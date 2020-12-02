#*********************************************************************
#   Copyright 2019 Regents of the University of California
#   All rights reserved
#*********************************************************************

FROM ruby:2.7

RUN apt-get update && \
    apt-get install -y bsdtar

RUN gem install bundler

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN bundle install

COPY . .

CMD ["bundle", "exec", "rspec", "spec"]
