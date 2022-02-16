#*********************************************************************
#   Copyright 2019 Regents of the University of California
#   All rights reserved
#*********************************************************************

FROM selenium/standalone-chrome

ENV JAVA_OPTS=-Dwebdriver.chrome.whitelistedIps= -Dwebdriver.chrome.allowedIps=

# The chrome image stores downloads into the following folder
# Ensure that the Capybara client can access these files
RUN mkdir -p /home/seluser/Downloads && \
    chmod 755 /home/seluser/Downloads
