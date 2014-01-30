#!/bin/sh

if [ ! -d /vagrant ]; then
    echo "This script is intended to be used on a VM."
    exit 1
fi

# Update index first
sudo apt-get update

# Essentials
sudo apt-get install -y git

# Mongo DB
sudo apt-get install -y mongodb-server

# Ruby
sudo apt-get install -y ruby1.9.3
sudo gem install bundler

# Gem dependencies
sudo apt-get install -y libssl-dev # for puma
