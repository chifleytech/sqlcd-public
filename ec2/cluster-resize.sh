#!/usr/bin/env bash
CLUSTER_NAME=$1
SIZE=$2
ecs-cli scale \
--capability-iam \
--size $SIZE \
--capability-iam \
--cluster-config $CLUSTER_NAME \
--ecs-profile my-profile
