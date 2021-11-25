#!/usr/bin/env bash

# Create new template and activate new template for instance group

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

# Check Cloudprober configuration file
echo
echo "Check Cloudprober configuration file '$CLOUDPROBER_CONFIG_FILE'"
if [ -e "$CLOUDPROBER_CONFIG_FILE" ]; then
	echo "OK: Found"
else
	echo "ERROR: Cloudprober configuration file not found!"
	exit 9
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

# New template name
MY_GCP_GCE_INSTANCE_TEMPLATE="$MY_GCP_GCE_INSTANCE_TEMPLATE-$RANDOM"

# Create instance template
# https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create
echo
echo "Create new instance template for Cloudprober servers"
echo "----------------------------------------------------"
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

# Update instance group
# https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/set-instance-template
echo
echo "Update instance group"
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
gcloud compute instance-groups managed set-instance-template "$MY_GCP_GCE_INSTANCE_GROUP" \
	--template="$MY_GCP_GCE_INSTANCE_TEMPLATE" \
	--region="$MY_GCP_REGION" \
	--project="$MY_GCP_PROJECT"

echo
echo "-----------------------------------------------------------------"
echo "The old template was not deleted. You can remove it after review."
echo "-----------------------------------------------------------------"
echo
echo "ALL DONE"
echo "--------"
echo
echo "Dashboard:"
echo "https://console.cloud.google.com/compute/instanceTemplates/list?project=$MY_GCP_PROJECT"
echo