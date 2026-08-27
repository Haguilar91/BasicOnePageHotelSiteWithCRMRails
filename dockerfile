FROM phusion/passenger-ruby34:latest

ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT="development:test"

ARG RAILS_MASTER_KEY
ENV RAILS_MASTER_KEY=${RAILS_MASTER_KEY}

# libvips backs ActiveStorage's image variants/analysis; imagemagick (the
# `magick`/`convert` CLI) is what MiniMagick shells out to for CompressImageJob.
RUN apt-get update && apt-get install -y \
    libvips \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# compose.yaml bind-mounts the host checkout over /home/app/webapp, and bind
# mounts map ownership by numeric UID/GID rather than by name. phusion's `app`
# user is UID 9999, so against a host checkout owned by UID 1000 the app can't
# write log/, tmp/ or storage/ (it crashes on boot), and anything it does write
# lands on the host owned by 9999 — which is why `git pull` then needs sudo.
# Align `app` with the host account instead; deploy.sh passes the real values.
# The Ubuntu base already ships an unused `ubuntu` user/group at 1000, so drop
# whatever holds the target ids first — remapping with -o instead would leave
# two names on one uid and make logs/ps report the app running as "ubuntu".
ARG APP_UID=1000
ARG APP_GID=1000
RUN set -eu; \
    taken_user="$(getent passwd ${APP_UID} | cut -d: -f1 || true)"; \
    if [ -n "$taken_user" ] && [ "$taken_user" != "app" ]; then userdel -r "$taken_user" || true; fi; \
    taken_group="$(getent group ${APP_GID} | cut -d: -f1 || true)"; \
    if [ -n "$taken_group" ] && [ "$taken_group" != "app" ]; then groupdel "$taken_group" || true; fi; \
    groupmod -g ${APP_GID} app; \
    usermod -u ${APP_UID} -g ${APP_GID} app; \
    chown -R ${APP_UID}:${APP_GID} /home/app

RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
COPY docker/nginx.conf /etc/nginx/sites-enabled/webapp.conf

# Automatically run database migrations on container start
COPY docker/migrate.sh /etc/my_init.d/99_migrate.sh

WORKDIR /home/app/webapp

# Copy Gemfile and lock to install gems during build
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN bundle exec rails assets:precompile && \
    mkdir -p storage log tmp/pids vendor/bundle && \
    chown -R app:app /home/app/webapp

EXPOSE 80