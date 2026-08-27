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

# vendor/bundle is a named volume layered over the bind mount, so it is NOT the
# host checkout and the chowns in deploy.sh never reach it. Docker creates a
# fresh one owned by root (the image has no such path — .dockerignore excludes
# it), which leaves `app` unable to install gems. Fix it while we still hold
# root, and only when it's actually wrong so we don't walk the gem tree on
# every boot.
if [ "$(id -u)" = "0" ]; then
  mkdir -p vendor/bundle
  if [ "$(stat -c %u vendor/bundle)" != "$(id -u app)" ]; then
    echo "Fixing ownership of the gem volume (vendor/bundle)..."
    chown -R app:app vendor/bundle
  fi
fi

run_as_app bash -c 'bundle check || bundle install'
run_as_app bundle exec rails db:migrate

# compose.yaml bind-mounts the host checkout over /home/app/webapp, which hides
# the public/assets the dockerfile precompiled at build time. public/assets is
# also gitignored, so `git pull` never refreshes it either. Without this step
# the container serves whatever stale CSS/JS happens to sit on the host, and
# any stylesheet change silently never reaches production.
run_as_app bundle exec rails assets:precompile
