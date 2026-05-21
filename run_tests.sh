#! /bin/bash

# This script will launch tests when running as an ECS Task

source ./ecs-helpers.sh

export label="Run End to End Tests (${INGEST_FILES})"
export statfile="/tmp/end2end.txt"

mkdir -p /tmp/downloads

touch /tmp/downloads/chrome_dowloads_here.txt

task_init

FAIL=0

# Return Code ignores tee 
set -o pipefail
bundle exec rspec /spec/test --no-color 2>&1 | tee -a $statfile || FAIL=1
# Restore RC
set +o pipefail

rptfile="$(date +%Y%m%d-%H%M%S).txt"
aws s3 cp $statfile "s3://${S3REPORT_BUCKET}/end2end/${rptfile}"

egrep "^(Finished in|[0-9]+ examples,)" $statfile > $statfile.slack
echo "" >> $statfile.slack
echo '```' >> $statfile.slack
echo 'Details' >> $statfile.slack
egrep "\(FAILED -" $statfile | head -5 >> $statfile.slack
echo '```' >> $statfile.slack
echo "" >> $statfile.slack
echo "${baseurl}ops/s3-reports/retrieve?report=end2end%2F${rptfile}" >> $statfile.slack

if [ $FAIL -eq 1 ]
then
  task_fail
else
  task_complete Y
fi
