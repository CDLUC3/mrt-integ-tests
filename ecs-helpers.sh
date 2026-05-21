#! /bin/bash

make_status() {
  datetime=$(TZ="America/Los_Angeles" date "+%Y-%m-%d %H:%M:%S")
  status=$1
  duration=$2

  echo $(jq -n \
    --arg task_datetime "$datetime" \
    --arg task_environment "$MERRITT_ECS" \
    --arg task_status "$status" \
    --arg task_label "$label" \
    --arg task_duration "${duration}" \
    '$ARGS.named')
}

task_init() {
  TZ="America/Los_Angeles" date "+ ==> %Y-%m-%d %H:%M:%S: START: $label for $MERRITT_ECS" | tee $statfile
  echo $(make_status "STARTED" "")
  export STARTTIME=$(date +%s)
  if [[ -v SLACK_BOT_SSM ]]
  then
    export SLACK_BOT_TOKEN=$(aws ssm get-parameter --name "${SLACK_BOT_SSM}" --with-decryption --query "Parameter.Value" --output text)
  fi
}

task_complete() {
  local send_sms=${SLACK_ONSUCCESS:-N}

  TZ="America/Los_Angeles" date "+ ==> %Y-%m-%d %H:%M:%S: COMPLETE: $label for $MERRITT_ECS $(duration)" | tee -a $statfile
  echo $(make_status "COMPLETE" "$(duration)")

  if [[ "$send_sms" == "Y" ]]
  then
    subject=":white_check_mark: Merritt ECS $label for $MERRITT_ECS $(duration)"

    if [[ -v SLACK_BOT_TOKEN ]]
    then
      echo "*${subject}*" > $statfile.message
      echo "" >> $statfile.message
      if [[ -f "$statfile.slack" ]]
      then
        cat $statfile.slack >> $statfile.message
      fi
      ruby slack_message.rb $statfile.message
    else
      aws sns publish --topic-arn "$SNS_ARN" --subject "$subject" \
        --message "$(cat $statfile)"
    fi
  fi
}

task_fail() {
  local send_sms=${SLACK_ONFAIL:-Y}

  TZ="America/Los_Angeles" date "+ ==> %Y-%m-%d %H:%M:%S: FAIL: $label for $MERRITT_ECS $(duration)" | tee -a $statfile
  echo $(make_status "FAIL" "$(duration)")

  subject=":x: FAIL: Merritt ECS $label for $MERRITT_ECS $(duration)"

  if [[ "$send_sms" == "Y" ]]
  then
    if [[ -v SLACK_BOT_TOKEN ]]
    then
      echo "*${subject}*" > $statfile.message
      echo "" >> $statfile.message
      if [[ -f "$statfile.slack" ]]
      then
        cat $statfile.slack >> $statfile.message
      fi
      ruby slack_message.rb $statfile.message
    else
      aws sns publish --topic-arn "$SNS_ARN" --subject "$subject" \
        --message "$(cat $statfile)"
    fi
  fi
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