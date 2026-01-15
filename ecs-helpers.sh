#! /bin/bash

task_init() {
  date "+ ==> %Y-%m-%d %H:%M:%S: START: $label for $MERRITT_ECS" | tee $statfile
  export STARTTIME=$(date +%s)
}

task_complete() {
  date "+ ==> %Y-%m-%d %H:%M:%S: COMPLETE: $label for $MERRITT_ECS $(duration)" | tee -a $statfile
  subject="Merritt ECS $label for $MERRITT_ECS $(duration)"
  aws sns publish --topic-arn "$SNS_ARN" --subject "$subject" \
    --message "$(cat $statfile)"
}

task_fail() {
  date "+ ==> %Y-%m-%d %H:%M:%S: FAIL: $label for $MERRITT_ECS $(duration)" | tee -a $statfile
  subject="FAIL: Merritt ECS $label for $MERRITT_ECS $(duration)"
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