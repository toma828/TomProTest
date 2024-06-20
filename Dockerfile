# syntax=docker/dockerfile:1

# Base stage for common dependencies
FROM ruby:3.2.3
ENV LANG C.UTF-8
ENV TZ Asia/Tokyo
RUN apt-get update -qq \
&& apt-get install -y ca-certificates curl gnupg \
&& mkdir -p /etc/apt/keyrings \
&& curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
&& NODE_MAJOR=20 \
&& echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
&& wget --quiet -O - /tmp/pubkey.gpg https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
&& echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs yarn vim

# Common dependencies
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y \
    tzdata \
    libopencv-dev \
    python3 \
    python3-pip \
    python3-pip \
    python3-venv \
    libopencv-dev \
    wget \
    build-essential \
    libbluetooth-dev \
    tk-dev \
    uuid-dev \
    && ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python packages including OpenCV
RUN pip3 install --upgrade pip && \
    pip3 install opencv-python-headless

# Install Node.js and Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Install nodemon and esbuild
RUN npm install -g nodemon esbuild

# Set up Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Working directory for Rails app
WORKDIR /rails

# Install additional dependencies for build stage
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    libpq-dev \
    libvips \
    node-gyp \
    pkg-config \
    python-is-python3 \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ /usr/local/bundle/ruby/*/cache /usr/local/bundle/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install node modules
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    libvips \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy built artifacts from build stage
COPY --from=0 /usr/local/bundle /usr/local/bundle
COPY --from=0 /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER rails:rails

# Entrypoint script for initializing database and starting Rails server
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Expose Rails server port
EXPOSE 3000

# Default command to start Rails server
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]