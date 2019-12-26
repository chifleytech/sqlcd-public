#!/usr/bin/env bash
./compose-down.sh worker spark
./compose-down.sh master spark
./cluster-delete.sh spark