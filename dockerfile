FROM phusion/passenger-ruby34:latest

# Set correct environment variables
ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT="development:test"

# Accept the master key as a build argument
ARG RAILS_MASTER_KEY
ENV RAILS_MASTER_KEY=${RAILS_MASTER_KEY}

# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down

# Remove default Nginx site and configure for Rails /public root
RUN rm /etc/nginx/sites-enabled/default
COPY docker/nginx.conf /etc/nginx/sites-enabled/webapp.conf

# Set application home directory
WORKDIR /home/app/webapp

# Copy Gemfile and lock first to leverage Docker caching layers
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the application code
COPY . .

# Precompile assets and set up storage permissions for SQLite
RUN bundle exec rails assets:precompile && \
    mkdir -p storage log tmp/pids && \
    chown -R app:app /home/app/webapp

EXPOSE 80