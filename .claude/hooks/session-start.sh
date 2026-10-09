#!/bin/bash
#
# Set up Claude Code on the web sessions so that the app, specs and linters
# work. Local development environments are set up with script/setup instead.
#
# The cloud image comes with rbenv, nvm, Postgres, Redis and Playwright's
# Chromium. This script is idempotent and the container is cached after it ran.

set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# Persist environment variables for the rest of the session.
persist() {
  echo "$1" >> "$CLAUDE_ENV_FILE"
}

echo "== System packages =="
if ! command -v identify > /dev/null; then
  # ImageMagick is used by MiniMagick to process images.
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq imagemagick > /dev/null
fi

# Ferrum looks for chrome or chromium on the PATH.
if ! command -v chromium > /dev/null && [ -x /opt/pw-browsers/chromium ]; then
  ln -sf /opt/pw-browsers/chromium /usr/local/bin/chromium
fi

echo "== Ruby $(cat .ruby-version) =="
export RBENV_ROOT="${RBENV_ROOT:-/opt/rbenv}"
export PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"
rbenv install --skip-existing
gem install bundler --conservative --no-document
bundle install --quiet

echo "== Node $(cat .node-version) =="
export NVM_DIR="${NVM_DIR:-/opt/nvm}"
# nvm.sh fails with `set -u`.
set +u
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
nvm install "$(cat .node-version)" > /dev/null
set -u
node_bin="$(dirname "$(nvm which "$(cat .node-version)")")"
export PATH="$node_bin:$PATH"
persist "export PATH=\"$node_bin:\$PATH\""
command -v yarn > /dev/null || npm install --global --silent yarn
yarn install --frozen-lockfile --silent

echo "== Services =="
service postgresql start > /dev/null
service redis-server start > /dev/null 2>&1 || true # ulimit warning in containers
sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname = 'ofn'" | grep -q 1 ||
  sudo -u postgres psql -c "CREATE USER ofn WITH SUPERUSER CREATEDB PASSWORD 'f00d'"

echo "== Test database =="
RAILS_ENV=test DISABLE_SPRING=1 bin/rails db:prepare > /dev/null

echo "== Done =="
