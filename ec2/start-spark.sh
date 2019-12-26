#!/usr/bin/env bash
./cluster-create.sh spark m5.large 1
./compose-up.sh master spark 1024 3840
./compose-up.sh worker spark 1024 3841