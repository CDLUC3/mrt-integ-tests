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

echo "" >> $statfile.tmp
cat $statfile >> $statfile.tmp

mv $statfile.tmp $statfile

rptfile="end2end-$(date +%Y%m%d-%H%M%S).txt"
aws s3 cp $statfile "s3://${S3REPORT_BUCKET}/reports/${rptfile}"

mv $statfile $statfile.tmp

egrep "^(Finished in|[0-9]+ examples,)" $statfile.tmp > $statfile
echo "" >> $statfile
echo "To see a formatted version of the report, copy and paste the following URL into a browser:" >> $statfile
echo "" >> $statfile
echo "${baseurl}saved-reports/retrieve?report=reports%2F${rptfile}" >> $statfile
echo "" >> $statfile
cat $statfile.tmp >> $statfile

if [ $FAIL -eq 1 ]
then
  task_fail
else
  task_complete Y
fi
