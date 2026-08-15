#!/bin/bash

set -e
cd /home/app/webapp
bundle check || bundle install
bundle exec rails db:migrate

# compose.yaml bind-mounts the host checkout over /home/app/webapp, which hides
# the public/assets the dockerfile precompiled at build time. public/assets is
# also gitignored, so `git pull` never refreshes it either. Without this step
# the container serves whatever stale CSS/JS happens to sit on the host, and
# any stylesheet change silently never reaches production.
bundle exec rails assets:precompile
