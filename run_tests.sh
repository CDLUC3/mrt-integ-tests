#! /bin/bash

# This script will launch tests when running as an ECS Task

source ./ecs-helpers.sh

export label="Run End to End Tests (${INGEST_FILES})"
export statfile="/tmp/end2end.txt"

mkdir -p /tmp/downloads

touch /tmp/downloads/chrome_dowloads_here.txt

task_init

echo "<pre>" > $statfile
FAIL=0

# Return Code ignores tee 
set -o pipefail
bundle exec rspec /spec/test --no-color 2>&1 | tee -a $statfile || FAIL=1
# Restore RC
set +o pipefail

echo "</pre>" >> $statfile

header=$(egrep "^(Finished in|\d+ examples,)" $statfile)
sed -i '' "1i\\$header" $statfile

if [ $FAIL -eq 1 ]
then
  task_fail
else
  task_complete Y
fi
