#!/usr/bin/env bash
echo "" > stop-all.log
nohup ./stop-app.sh >> stop-all.log 2>&1&
nohup ./stop-gitlab.sh >> stop-all.log 2>&1&
nohup ./stop-postgres.sh >> stop-all.log 2>&1&
nohup ./stop-spark.sh >> stop-all.log 2>&1&
tail -f stop-all.log