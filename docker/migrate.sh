#!/bin/bash

set -e
cd /home/app/webapp

# These commands write through the bind mount (public/assets, the gem cache,
# SQLite's -wal/-shm sidecars), so whoever runs them owns those files on the
# HOST. Anything root-owned there makes the next `git pull` need sudo, so run
# them as `app` — the user Passenger serves as, and whose UID the dockerfile
# aligns with the host account.
#
# /etc/my_init.d scripts normally run as root (that's why phusion ships
# setuser), but don't assume it: setuser needs root to switch users and would
# fail outright if this already runs as app. Drop privileges only when we
# actually hold them.
run_as_app() {
  if [ "$(id -u)" = "0" ] && command -v setuser >/dev/null 2>&1; then
    setuser app "$@"
  else
    "$@"
  fi
}

run_as_app bash -c 'bundle check || bundle install'
run_as_app bundle exec rails db:migrate

# compose.yaml bind-mounts the host checkout over /home/app/webapp, which hides
# the public/assets the dockerfile precompiled at build time. public/assets is
# also gitignored, so `git pull` never refreshes it either. Without this step
# the container serves whatever stale CSS/JS happens to sit on the host, and
# any stylesheet change silently never reaches production.
run_as_app bundle exec rails assets:precompile
