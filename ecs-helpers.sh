#! /bin/bash

task_init() {
  date "+ ==> %Y-%m-%d %H:%M:%S: $label Started" | tee $statfile
  export STARTTIME=$(date +%s)
}

task_complete() {
  date "+ ==> %Y-%m-%d %H:%M:%S: $label Complete $(duration)" | tee -a $statfile
  subject="Merritt ECS $label for $MERRITT_ECS $(duration)"
  echo " ==> $subject"
  aws sns publish --topic-arn "$SNS_ARN" --subject "$subject" \
    --message "$(cat $statfile)"
}

task_fail() {
  date "+ ==> %Y-%m-%d %H:%M:%S: $label Failed $(duration)" | tee -a $statfile
  subject="FAIL: Merritt ECS $label for $MERRITT_ECS $(duration)"
  echo " ==> $subject"
  aws sns publish --topic-arn "$SNS_ARN" --subject "$subject" \
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