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

# Whether the site is indexable is invisible from the outside — nothing looks
# broken either way — and it is the one thing that has to change on launch
# day. Report it on every deploy so it can't be silently forgotten. Ask the
# running container rather than guessing from the environment, so this
# reflects what crawlers will actually be served.
CANONICAL_HOST="${SITE_HOST:-hotelmesondelbosque.com.mx}"
echo
echo "--------------------------------------------------------------------"
echo " Canonical domain : ${CANONICAL_HOST}"

ROBOTS=""
for _ in 1 2 3 4 5 6 7 8 9 10; do
  ROBOTS="$(curl -sf -H "Host: ${CANONICAL_HOST}" http://localhost:8443/robots.txt 2>/dev/null || true)"
  [ -n "$ROBOTS" ] && break
  sleep 2
done

if [ -z "$ROBOTS" ]; then
  echo " Search engines   : could not check (app still starting?)"
  echo "                    Try: curl -H 'Host: ${CANONICAL_HOST}' http://localhost:8443/robots.txt"
elif printf '%s' "$ROBOTS" | grep -q "^Sitemap:"; then
  echo " Search engines   : INDEXING THIS SITE"
  echo "                    Submit the sitemap once, in Google Search Console:"
  echo "                    https://${CANONICAL_HOST}/sitemap.xml"
else
  echo " Search engines   : blocked (robots.txt says Disallow: /)"
  if [ "${ALLOW_INDEXING}" = "false" ]; then
    echo "                    Reason: ALLOW_INDEXING=false — the pre-launch hold."
  else
    echo "                    Reason: this deploy is not answering on the canonical domain."
  fi
  echo "                    To go live: unset SITE_HOST and ALLOW_INDEXING,"
  echo "                    point ${CANONICAL_HOST} here, and re-run this script."
  echo "                    Full checklist: DEPLOY.md"
fi
echo "--------------------------------------------------------------------"
echo

echo "Tailing logs (Ctrl+C to exit, container keeps running)..."
docker compose logs -f --tail=50