#!/bin/sh

if [ ! -d /vagrant ]; then
    echo "This script is intended to be used on a VM."
    exit 1
fi

set -x

cd /app

source .powenv
export BUNDLE_PATH=$HOME/bundle

bundle install --jobs=4
RACK_ENV=${RACK_ENV:-development} bundle exec ruby app.rb -o 0.0.0.0 -p 8080
