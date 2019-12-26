#!/usr/bin/env bash
./cluster-create.sh sqlcd m5.large 1
./compose-up.sh app sqlcd 2048 7681