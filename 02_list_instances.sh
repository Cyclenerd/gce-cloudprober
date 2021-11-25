#!/usr/bin/env bash

# List instances

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
echo "List instances in group"
echo "-----------------------"
echo "Name    : $MY_GCP_GCE_INSTANCE_GROUP"
echo "Region  : $MY_GCP_REGION"
echo "Project : $MY_GCP_PROJECT"
echo
gcloud compute instance-groups managed list-instances "$MY_GCP_GCE_INSTANCE_GROUP" \
	--region="$MY_GCP_REGION" \
	--project="$MY_GCP_PROJECT"

echo
echo "List instances with label 'cloudprober-server:yes'"
echo "--------------------------------------------------"
gcloud compute instances list \
	--filter="labels.cloudprober-server:yes" \
	--project="$MY_GCP_PROJECT"

MY_GCE_GCE_INSTANCES_IPS=$(gcloud compute instances list \
	--filter="labels.cloudprober-server:yes" \
	--format="csv[no-heading](NAME, INTERNAL_IP)" \
	--project="$MY_GCP_PROJECT")

echo
echo "ALL DONE"
echo "--------"
echo
echo "Your internal service URLs:"
# Loop internal ips
while IFS=',' read -r MY_GCE_GCE_INSTANCE_NAME MY_GCE_GCE_INSTANCE_IP || [[ -n "$MY_GCE_GCE_INSTANCE_IP" ]]; do
echo
echo "Instance: $MY_GCE_GCE_INSTANCE_NAME:"
echo "curl 'http://$MY_GCE_GCE_INSTANCE_IP:$CLOUDPROBER_PORT/status'"
done <<<"$MY_GCE_GCE_INSTANCES_IPS"
echo
echo "Dashboard:"
echo "https://console.cloud.google.com/compute/instanceGroups/details/$MY_GCP_REGION/$MY_GCP_GCE_INSTANCE_GROUP?project=$MY_GCP_PROJECT"
echo