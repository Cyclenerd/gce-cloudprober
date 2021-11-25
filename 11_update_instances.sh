#!/usr/bin/env bash

# Add and update Compute Engine managed instances in group

# 'rolling-action' unfortunately causes a temporary outage...
# ...so I rather try recreate the instances one by one
#
# gcloud compute instance-groups managed rolling-action replace
# https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/rolling-action/replace

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

# List instances present in the managed instance group
# https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/list-instances
echo
echo "List current instances in group"
echo "-------------------------------"
echo "Name     : $MY_GCP_GCE_INSTANCE_GROUP"
echo "Region   : $MY_GCP_REGION"
echo "Project  : $MY_GCP_PROJECT"
echo
gcloud compute instance-groups managed list-instances "$MY_GCP_GCE_INSTANCE_GROUP" \
	--region="$MY_GCP_REGION" \
	--project="$MY_GCP_PROJECT"
MY_GCE_GCE_INSTANCES=$(gcloud compute instance-groups managed list-instances "$MY_GCP_GCE_INSTANCE_GROUP" \
	--format="csv[no-heading](NAME, ZONE)" \
	--region="$MY_GCP_REGION" \
	--project="$MY_GCP_PROJECT")

echo
echo "Recreate instances in group"
echo "---------------------------"
echo "Name    : $MY_GCP_GCE_INSTANCE_GROUP"
echo "Region  : $MY_GCP_REGION"
echo "Project : $MY_GCP_PROJECT"
# Loop instances
while IFS=',' read -r MY_GCE_GCE_INSTANCE_NAME MY_GCE_GCE_INSTANCE_ZONE || [[ -n "$MY_GCE_GCE_INSTANCE_ZONE" ]]; do
	echo
	echo "Recreate instance : $MY_GCE_GCE_INSTANCE_NAME"
	echo "---------------------------------------------"
	echo "Please wait..."
	gcloud compute instance-groups managed recreate-instances "$MY_GCP_GCE_INSTANCE_GROUP" \
	--instances="$MY_GCE_GCE_INSTANCE_NAME" \
	--region="$MY_GCP_REGION" \
	--project="$MY_GCP_PROJECT"
	echo "Wait until state of managed instance group is stable again..."
	if ! gcloud compute instance-groups managed wait-until "$MY_GCP_GCE_INSTANCE_GROUP" \
		--stable \
		--region "$MY_GCP_REGION" \
		--project="$MY_GCP_PROJECT" ; then
		echo "ERROR: Please check instance group"
		exit 1
	fi
	echo "Wait 90sec to be save..."
	sleep 90
done <<<"$MY_GCE_GCE_INSTANCES"


echo
echo "ALL DONE"
echo "--------"
echo
echo "Dashboard:"
echo "https://console.cloud.google.com/compute/instanceGroups/details/$MY_GCP_REGION/$MY_GCP_GCE_INSTANCE_GROUP?project=$MY_GCP_PROJECT"
echo