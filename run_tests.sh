#! /bin/bash

# This script will launch tests when running as an ECS Task

ui=$(aws servicediscovery discover-instances \
          --service-name ui --namespace-name merritt-ecs-dev | \
          jq -r ".Instances[0].Attributes.AWS_INSTANCE_IPV4")
export PREVIEW_URL=http://${ui}:8086

bundle exec rspec /spec/test