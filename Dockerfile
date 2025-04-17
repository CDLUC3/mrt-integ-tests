#*********************************************************************
#   Copyright 2019 Regents of the University of California
#   All rights reserved
#*********************************************************************

FROM public.ecr.aws/docker/library/ruby:3.2

RUN apt-get update -y && \
    apt-get install -y libarchive-tools zip && \
    apt-get -y upgrade

RUN gem install bundler

COPY Gemfile* ./

RUN bundle install

COPY . .

# https://serverfault.com/questions/683605/docker-container-time-timezone-will-not-reflect-changes
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# CMD ["bundle", "exec", "rspec", "/spec/test/demo_spec.rb:33"]
CMD ["bundle", "exec", "rspec", "/spec/test/demo_spec.rb:27"]
