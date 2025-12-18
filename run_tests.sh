#! /bin/bash

# This script will launch tests when running as an ECS Task

source ./ecs-helpers.sh

export label="Run End to End Tests (${INGEST_FILES})"
export statfile="/tmp/end2end.txt"

mkdir -p /tmp/downloads

task_init

bundle exec rspec /spec/test --no-color > $statfile 2>&1 || task_fail

task_complete
