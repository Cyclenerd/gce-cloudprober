#!/usr/bin/env bash

# Project
MY_GCP_REGION=${MY_GCP_REGION:-"europe-west4"}
MY_GCP_PROJECT=${MY_GCP_PROJECT:-"my-cloudprober-probes"}
MY_GCP_ZONES=${MY_GCP_ZONES:-"$MY_GCP_REGION-a,$MY_GCP_REGION-b,$MY_GCP_REGION-c"}

# Service account name
MY_GCP_SA_NAME=${MY_GCP_SA_NAME:-"sa-gce-cloudprober"}
MY_GCP_SA_DISPLAY_NAME=${MY_GCP_SA_DISPLAY_NAME:-"GCE cloudprober"}
MY_GCP_SA_DESCRIPTION=${MY_GCP_SA_DESCRIPTION:-"Service account for Google Compute Engine Cloudprober monitoring server"}
MY_GCP_SA_ROLES=(
	'roles/logging.logWriter'
	'roles/monitoring.metricWriter'
	'roles/monitoring.viewer'
)

# Health check
MY_GCP_GCE_HEALTH_CHECK=${MY_GCP_GCE_HEALTH_CHECK:-"health-check-cloudprober"}

# Instance / server
MY_DOCKER_SOURCE_IMAGE=${MY_DOCKER_SOURCE_IMAGE:-"cloudprober/cloudprober:latest"}
MY_GCP_GCE_NAME=${MY_GCP_GCE_NAME:-"cloudprober"}
MY_GCP_GCE_TYPE=${MY_GCP_GCE_TYPE:-"e2-micro"}
MY_GCP_GCE_DISK_BOOT_NAME=${MY_GCP_GCE_DISK_BOOT_NAME:-"disk-boot-$MY_GCP_GCE_NAME"}
MY_GCP_GCE_INSTANCE_TEMPLATE=${MY_GCP_GCE_INSTANCE_TEMPLATE:-"instance-template-cloudprober"}
MY_GCP_SUBNET=${MY_GCP_SUBNET:-"projects/$MY_GCP_PROJECT/regions/$MY_GCP_REGION/subnetworks/default"}

# Instance group
MY_GCP_GCE_INSTANCE_GROUP=${MY_GCP_GCE_INSTANCE_GROUP:-"instance-group-cloudprober"}
MY_GCP_GCE_INSTANCE_GROUP_MIN=${MY_GCP_GCE_INSTANCE_GROUP_MIN:-"3"}
MY_GCP_GCE_INSTANCE_GROUP_MAX=${MY_GCP_GCE_INSTANCE_GROUP_MAX:-"6"}

# Cloudprober configuration
# Please, only change if you know what you are doing
CLOUDPROBER_HOST="0.0.0.0"
CLOUDPROBER_PORT="9313"
CLOUDPROBER_CONFIG_FILE="cloudprober_config.cfg"