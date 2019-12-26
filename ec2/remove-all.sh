#!/usr/bin/env bash
echo "" > remove-all.log
nohup ./cluster-delete.sh vcs >> remove-all.log 2>&1&
nohup ./cluster-delete.sh db >> remove-all.log 2>&1&
nohup ./cluster-delete.sh app >> remove-all.log 2>&1&
nohup ./cluster-delete.sh spark >> remove-all.log 2>&1&
tail -f remove-all.log