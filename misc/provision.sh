#!/bin/sh

if [ ! -d /vagrant ]; then
    echo "This script is intended to be used on a VM."
    exit 1
fi

set -x

# Update index first
[ "$UPDATE" != no ] && sudo apt-get update

# Essentials
sudo apt-get install -y git

# Mongo DB
sudo apt-get install -y mongodb-server

# Gem dependencies
sudo apt-get install -y libssl-dev # for puma

# rbenv
if [ -e ~/.rbenv ]; then
    ( cd ~/.rbenv && git pull --force )
else
    git clone https://github.com/sstephenson/rbenv ~/.rbenv
fi
if [ -e ~/.rbenv/plugins/ruby-build ]; then
    ( cd ~/.rbenv/plugins/ruby-build && git pull --force )
else
    git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
fi

# rnenv config
cat <<'RBENV_CONFIG' > ~/.bashrc
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
RBENV_CONFIG
[ -z "$RBENV_SHELL" ] && . ~/.bashrc

# Ruby
RUBY_VERSION=`cat /app/.ruby-version`
yes no | rbenv install $RUBY_VERSION
rbenv global $RUBY_VERSION
rbenv shell $RUBY_VERSION

# Bundler
gem install bundler
rbenv rehash
