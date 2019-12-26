#!/usr/bin/env bash
CONTAINER=$1
NAMESPACE=$2
CPU=$3
MEMORY=$4
source configure.sh
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
service up \
--private-dns-namespace $NAMESPACE \
--vpc $VPC \
--enable-service-discovery \
--create-log-groups \
--cluster-config default-fargate \
--ecs-profile my-profile

