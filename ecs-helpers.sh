#! /bin/bash

task_init() {
  echo " ==> $label Started"
  date "+%Y-%m-%d %H:%M:%S: $label Started" > $statfile
  export STARTTIME=$(date +%s)
}

task_complete() {
  echo " ==> $label Complete $(duration)"
  date "+%Y-%m-%d %H:%M:%S: $label Complete" >> $statfile
  aws sns publish --topic-arn "$SNS_ARN" --subject "Merritt ECS $label for $MERRITT_ECS $(duration)" \
    --message "$(cat $statfile)"
}

task_fail() {
  echo " ==> $label Failed $(duration)"
  date "+%Y-%m-%d %H:%M:%S: $label Failed" >> $statfile
  aws sns publish --topic-arn "$SNS_ARN" --subject "FAIL: Merritt ECS $label for $MERRITT_ECS $(duration)" \
    --message "$(cat $statfile)"
  exit 1
}

duration() {
  duration=$(( $(date +%s) - $STARTTIME ))
  min=$(( $duration / 60 ))
  sec=$(( $duration % 60 ))
  # Pad seconds with a leading zero when < 10
  if [ "$sec" -lt 10 ]; then sec="0$sec"; fi
  echo "($min:$sec sec)"
}