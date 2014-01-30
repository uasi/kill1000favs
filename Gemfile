source 'https://rubygems.org'

ruby '2.1.0'

# As of 2013-07-27, these gems do not officially support Ruby 2.0.0:
# - sinatra-env 0.0.2
# - sinatra-flash 0.3.0
# - sinatra-r18n 1.1.5
# - omniauth-twitter 1.0.0
# - pony 1.5
# - puma 2.4.0 (no mention in its document but it passes tests on 2.0.0)
# - slim 2.0.0 (ditto)

# and these do support 2.0.0:
# - sinatra 1.4.0
# - omniauth 1.1.4
# - better_errors 0.9.0
# - binding_of_caller 0.7.2

gem 'puma', '~> 2.4'
gem 'sinatra', '~> 1.4'
gem 'sinatra-env'
gem 'sinatra-flash', require: 'sinatra/flash'
gem 'sinatra-r18n', '~> 1.1', require: 'sinatra/r18n'
gem 'slim', '~> 2.0'
gem 'twitter', '~> 4.8'
gem 'omniauth', '~> 1.1'
gem 'omniauth-twitter', '~> 1.0'
gem 'pony', '~> 1.5'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'sinatra-contrib', require: 'sinatra/reloader'
end
