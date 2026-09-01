# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t new_orient_vue .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name new_orient_vue new_orient_vue

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.7
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages. Node and Chromium are needed at runtime too:
# Grover renders PDFs by running Puppeteer via node.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 chromium && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment. Puppeteer uses the system Chromium instead of
# downloading its own copy.
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    PUPPETEER_SKIP_DOWNLOAD="true" \
    PUPPETEER_EXECUTABLE_PATH="/usr/bin/chromium"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install node modules (Puppeteer's Chromium download is skipped — see base ENV)
COPY package.json package-lock.json ./
RUN npm ci

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Build the Vite assets. Dummy secret/DB values — nothing connects at build
# time, but the environment must load. Dev-only node modules (vite) are
# pruned afterwards; puppeteer stays for Grover PDF rendering at runtime.
RUN SECRET_KEY_BASE_DUMMY=1 DATABASE_URL=postgresql://dummy:dummy@localhost/dummy ./bin/rails assets:precompile && \
    npm prune --omit=dev




# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Run Puma directly on $PORT (Railway injects it and routes its proxy there).
# Thruster is skipped: it would listen on 80 and pin Puma to its own internal
# port 3000, hiding the app from Railway's proxy.
# Run Puma directly with the config file: `rails server` overrides the bind
# host to 0.0.0.0 (IPv4 only), which Railway's IPv6 proxy can't reach, while
# config/puma.rb binds [::] (IPv4 + IPv6) on $PORT.
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
