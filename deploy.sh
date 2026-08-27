#!/bin/bash
set -e
cd ~/Sites/Hotel




echo "Backing up production database..."
mkdir -p ~/backups
cp storage/production.sqlite3 ~/backups/production_$(date +%Y%m%d_%H%M%S).sqlite3

echo "Pulling latest code..."
git pull origin main

echo "Fixing permissions..."
chmod 777 -Rv .

echo "Rebuilding and restarting container..."
docker compose build
docker compose up -d --force-recreate

echo "Tailing logs (Ctrl+C to exit, container keeps running)..."
docker compose logs -f --tail=50