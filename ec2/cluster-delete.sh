#!/usr/bin/env bash
CLUSTER_NAME=$1
ecs-cli down --cluster $CLUSTER_NAME \
--cluster-config $CLUSTER_NAME \
--ecs-profile my-profile \
--force
echo "Finished Deleting Cluster "$CLUSTER_NAME

