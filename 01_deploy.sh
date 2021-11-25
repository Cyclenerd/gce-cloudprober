#!/usr/bin/env bash

# Deploy cloudprober monitoring servers

# Load config
MY_DEFAULT_CONFIG="./default_config.sh"
MY_CONFIG="./my_config.sh"
echo "Load default config file '$MY_DEFAULT_CONFIG'"
if [ -e "$MY_DEFAULT_CONFIG" ]; then
	# ignore SC1090
	# shellcheck source=/dev/null
	source "$MY_DEFAULT_CONFIG"
else
	echo "ERROR: Default config file not found!"
	exit 9
fi
if [ -e "$MY_CONFIG" ]; then
	echo "Load config file '$MY_CONFIG'"
	# ignore SC1090
	# shellcheck source=/dev/null
	source "$MY_CONFIG"
fi

# Create service account
echo
echo "Create service account"
echo "----------------------"
echo "Name         : $MY_GCP_SA_NAME"
echo "Display name : $MY_GCP_SA_DISPLAY_NAME"
echo "Project      : $MY_GCP_PROJECT"
echo
if gcloud iam service-accounts create "$MY_GCP_SA_NAME" \
	--display-name="$MY_GCP_SA_DISPLAY_NAME" \
	--description="$MY_GCP_SA_DESCRIPTION" \
	--project="$MY_GCP_PROJECT"; then
	echo "Please wait... (15sec)"
	sleep 15
fi

# Get service account ID
echo
echo "Get service account ID"
echo "----------------------"
echo "Name    : $MY_GCP_SA_NAME"
echo "Project : $MY_GCP_PROJECT"
echo
gcloud iam service-accounts list \
	--filter="email ~ ^$MY_GCP_SA_NAME\@" \
	--project="$MY_GCP_PROJECT"
MY_GCP_SA_ID=$(gcloud iam service-accounts list --filter="email ~ ^$MY_GCP_SA_NAME\@" --format="value(email)" --project="$MY_GCP_PROJECT")
if [[ "$MY_GCP_SA_ID" == *'@'* ]]; then
	echo "Service account identifier: $MY_GCP_SA_ID"
else
	echo "ERROR: Service account identifier could not be detected"
	exit 5
fi

# Add IAM policy binding for role
echo
echo "Add IAM policy binding (roles)"
echo "------------------------------"
echo "Service account : $MY_GCP_SA_ID"
echo "Project         : $MY_GCP_PROJECT"
echo
# shellcheck disable=SC2153
for MY_GCP_SA_ROLE in "${MY_GCP_SA_ROLES[@]}"; do
	echo "» $MY_GCP_SA_ROLE"
	gcloud projects add-iam-policy-binding "$MY_GCP_PROJECT" \
		--member=serviceAccount:"$MY_GCP_SA_ID" \
		--role="$MY_GCP_SA_ROLE"
done

# Create health check
# https://cloud.google.com/sdk/gcloud/reference/compute/health-checks/create
echo
echo "Create health check for Cloudprober"
echo "-----------------------------------"
echo "Name             : $MY_GCP_GCE_HEALTH_CHECK"
echo "Project          : $MY_GCP_PROJECT"
echo "Cloudprober port : $CLOUDPROBER_PORT"
echo
gcloud compute health-checks create http "$MY_GCP_GCE_HEALTH_CHECK" \
	--port="$CLOUDPROBER_PORT" \
	--request-path="/config"   \
	--no-enable-logging        \
	--check-interval="10"      \
	--timeout="5"              \
	--unhealthy-threshold="3"  \
	--healthy-threshold="3"    \
	--project="$MY_GCP_PROJECT"

# Check Cloudprober configuration file
echo
echo "Check Cloudprober configuration file '$CLOUDPROBER_CONFIG_FILE'"
if [ -e "$CLOUDPROBER_CONFIG_FILE" ]; then
	echo "OK: Found"
else
	echo "ERROR: Cloudprober configuration file not found!"
	exit 9
fi

# Create instance template
# https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create
echo
echo "Create instance template for Cloudprober servers"
echo "------------------------------------------------"
echo "Name               : $MY_GCP_GCE_INSTANCE_TEMPLATE"
echo "Machine type       : $MY_GCP_GCE_TYPE"
echo "Subnet             : $MY_GCP_SUBNET"
echo "Service account    : $MY_GCP_SA_ID"
echo "Region             : $MY_GCP_REGION"
echo "Boot disk name     : $MY_GCP_GCE_DISK_BOOT_NAME"
echo "Docker image       : $MY_DOCKER_SOURCE_IMAGE"
echo "Project            : $MY_GCP_PROJECT"
echo

echo
echo "Please wait..."
gcloud compute instance-templates create-with-container "$MY_GCP_GCE_INSTANCE_TEMPLATE" \
	--machine-type="$MY_GCP_GCE_TYPE" \
	--subnet="$MY_GCP_SUBNET" \
	--no-address \
	--network-tier="PREMIUM" \
	--metadata="google-logging-enabled=true,block-project-ssh-keys=true" \
	--maintenance-policy="MIGRATE" \
	--service-account="$MY_GCP_SA_ID" \
	--scopes="default" \
	--region="$MY_GCP_REGION" \
	--image-family="cos-stable" \
	--image-project="cos-cloud" \
	--boot-disk-size="10GB" \
	--boot-disk-type="pd-balanced" \
	--boot-disk-device-name="$MY_GCP_GCE_DISK_BOOT_NAME" \
	--no-shielded-secure-boot \
	--shielded-vtpm \
	--shielded-integrity-monitoring \
	--container-image="$MY_DOCKER_SOURCE_IMAGE" \
	--container-env="CLOUDPROBER_HOST=$CLOUDPROBER_HOST,CLOUDPROBER_PORT=$CLOUDPROBER_PORT" \
	--metadata-from-file="cloudprober_config=$CLOUDPROBER_CONFIG_FILE" \
	--container-restart-policy="always" \
	--labels="cloudprober-server=yes,config-image-family=cos-stable,config-image-project=cos-cloud" \
	--project="$MY_GCP_PROJECT"

# Create instance group
# https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/create
echo
echo "Create instance group"
echo "---------------------"
echo "Name               : $MY_GCP_GCE_INSTANCE_GROUP"
echo "Base name (GCE VM) : $MY_GCP_GCE_NAME"
echo "Template           : $MY_GCP_GCE_INSTANCE_TEMPLATE"
echo "Health check       : $MY_GCP_GCE_HEALTH_CHECK"
echo "Region             : $MY_GCP_REGION"
echo "Zones              : $MY_GCP_ZONES"
echo "Project            : $MY_GCP_PROJECT"
echo
echo "Please wait..."
gcloud compute instance-groups managed create "$MY_GCP_GCE_INSTANCE_GROUP" \
	--base-instance-name="$MY_GCP_GCE_NAME" \
	--description="GCE managed instance group for monitoring server" \
	--template="$MY_GCP_GCE_INSTANCE_TEMPLATE" \
	--health-check="$MY_GCP_GCE_HEALTH_CHECK" \
	--region="$MY_GCP_REGION" \
	--initial-delay="300" \
	--size="1" \
	--zones="$MY_GCP_ZONES" \
	--instance-redistribution-type="PROACTIVE" \
	--target-distribution-shape="EVEN" \
	--project="$MY_GCP_PROJECT"

# Set auto scaling
# https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/set-autoscaling
echo
echo "Add autoscaling to instance group"
echo "---------------------------------"
echo "Name      : $MY_GCP_GCE_INSTANCE_GROUP"
echo "Min / Max : $MY_GCP_GCE_INSTANCE_GROUP_MIN / $MY_GCP_GCE_INSTANCE_GROUP_MAX"
echo "Region    : $MY_GCP_REGION"
echo "Project   : $MY_GCP_PROJECT"
echo
echo "Please wait..."
gcloud compute instance-groups managed set-autoscaling "$MY_GCP_GCE_INSTANCE_GROUP" \
	--region "$MY_GCP_REGION" \
	--cool-down-period="60" \
	--min-num-replicas="$MY_GCP_GCE_INSTANCE_GROUP_MIN" \
	--max-num-replicas="$MY_GCP_GCE_INSTANCE_GROUP_MAX" \
	--target-cpu-utilization="0.8" \
	--mode="on" \
	--project="$MY_GCP_PROJECT"

echo
echo "-----------------------------------------------------------------------------------------------"
echo "It takes a while until all instances are started. You can check it with '02_list_instances.sh'."
echo "-----------------------------------------------------------------------------------------------"
echo
echo "ALL DONE"
echo "--------"
echo
echo "Dashboard:"
echo "https://console.cloud.google.com/compute/instanceGroups/details/$MY_GCP_REGION/$MY_GCP_GCE_INSTANCE_GROUP?project=$MY_GCP_PROJECT"
echo