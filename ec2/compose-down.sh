#!/usr/bin/env bash
CONTAINER=$1
CLUSTER_NAME=$2
source ../configure.sh
cp -f ecs-params.yml temp-$CONTAINER.yml
sed 's/${CPU}/'"${CPU}"'/g' ecs-params.yml | sed 's/${MEMORY}/'"${MEMORY}"'/g' > temp-$CONTAINER.yml
sed 's/${REGION}/'"${REGION}"'/g' $CONTAINER.yml > temp-$CONTAINER-compose.yml
echo "      subnets:" >> temp-$CONTAINER.yml
echo "        - "$SUBNET_1 >> temp-$CONTAINER.yml
echo "        - "$SUBNET_2 >> temp-$CONTAINER.yml
echo "      security_groups:" >> temp-$CONTAINER.yml
echo "        - "$SECURITY_GROUP >> temp-$CONTAINER.yml
ecs-cli compose \
--project-name $CONTAINER \
--file temp-$CONTAINER-compose.yml \
--ecs-params temp-$CONTAINER.yml \
service down \
--cluster-config $CLUSTER_NAME \
--ecs-profile my-profile \
--delete-namespace
