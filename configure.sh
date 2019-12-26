#!/usr/bin/env bash
export REGION=
export VPC=
export SUBNET_1=
export SUBNET_2=
export SECURITY_GROUP=

if [[ -z "${REGION}" ]]; then
  echo "Please set the REGION in configure.sh"
  exit 1
fi