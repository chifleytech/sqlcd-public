#!/usr/bin/env bash
./cluster-create.sh vcs m5.large 1
./compose-up.sh gitlab vcs 2048 7681