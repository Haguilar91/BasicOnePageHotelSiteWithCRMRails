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
    mkdir -p storage log tmp/pids && \
    chown -R app:app /home/app/webapp

EXPOSE 80