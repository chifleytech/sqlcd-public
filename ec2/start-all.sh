#!/usr/bin/env bash
echo "" > start-all.log
./start-gitlab.sh >> start-all.log 2>&1&
./start-postgres.sh >> start-all.log 2>&1&
./start-spark.sh >> start-all.log 2>&1&
./start-app.sh >> start-all.log 2>&1&
tail -f start-all.log