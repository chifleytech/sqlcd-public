#!/usr/bin/env bash
./cluster-create.sh db m5.large 1
./compose-up.sh postgres db 2048 6581