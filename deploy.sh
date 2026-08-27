#!/bin/bash
set -e
cd ~/Sites/Hotel

# Files a previous container left owned by root or UID 9999 make the git pull
# below fail with a confusing "permission denied". Say what to do instead.
if [ -n "$(find . -maxdepth 3 ! -user "$(id -u)" -print -quit 2>/dev/null)" ]; then
  echo "WARNING: some files here aren't owned by $(id -un) — left over from a"
  echo "container that ran before the UID fix. Run this once, then re-run deploy:"
  echo "    sudo chown -R $(id -u):$(id -g) ~/Sites/Hotel"
  echo
fi

echo "Backing up production database..."
mkdir -p ~/backups
cp storage/production.sqlite3 ~/backups/production_$(date +%Y%m%d_%H%M%S).sqlite3

echo "Pulling latest code..."
git pull origin main

echo "Rebuilding and restarting container..."
# Build the image with an `app` user matching this account, so everything the
# container writes back through the bind mount stays owned by us. This replaces
# the old `chmod 777 -R .`, which only ever changed permission bits and left
# ownership wrong, so container-written files kept re-breaking `git pull`.
export APP_UID="$(id -u)"
export APP_GID="$(id -g)"

docker compose build
docker compose up -d --force-recreate

echo "Tailing logs (Ctrl+C to exit, container keeps running)..."
docker compose logs -f --tail=50