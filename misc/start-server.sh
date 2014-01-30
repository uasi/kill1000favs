#!/bin/sh

if [ ! -d /vagrant ]; then
    echo "This script is intended to be used on a VM."
    exit 1
fi

set -x

# Go to the app directory
cd /app

# Export environment variables
source .powenv
export BUNDLE_PATH=$HOME/bundle
export PORT=8080

# Install gems
bundle install --jobs=4

# Configure port
sudo iptables -t nat -F PREROUTING
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $PORT

# Start server
RACK_ENV=${RACK_ENV:-development} bundle exec ruby app.rb -o 0.0.0.0 -p $PORT
