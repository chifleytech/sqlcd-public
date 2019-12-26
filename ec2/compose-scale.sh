#!/usr/bin/env bash
CONTAINER=$1
CLUSTER_NAME=$2
SCALE=$3
ecs-cli compose --project-name $CONTAINER \
--file $CONTAINER.yml service scale \
--cluster-config $CLUSTER_NAME \
--ecs-profile my-profile \
$SCALE