#!/bin/bash

set -e
cd /home/app/webapp
bundle check || bundle install
bundle exec rails db:migrate
