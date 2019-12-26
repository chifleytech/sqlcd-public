#!/usr/bin/env bash
KEY_PAIR_NAME=id_rsa
CLUSTER_NAME=$1
INSTANCE_TYPE=$2
SIZE=$3
source ../configure.sh

ecs-cli configure \
--region $REGION \
--default-launch-type EC2 \
--cluster $CLUSTER_NAME \
--config-name $CLUSTER_NAME

ecs-cli up \
--vpc $VPC \
--subnets $SUBNET_1,$SUBNET_2 \
--security-group $SECURITY_GROUP \
--keypair $KEY_PAIR_NAME  \
--capability-iam \
--instance-type $INSTANCE_TYPE  \
--size $SIZE \
--cluster-config $CLUSTER_NAME \
--ecs-profile my-profile \
--force
echo "Finished Creating Cluster "$CLUSTER_NAME