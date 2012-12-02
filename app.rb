require 'bundler'
Bundler.require

### Settings

Faraday.default_adapter = :em_synchrony

enable :logging
enable :sessions

use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'],
                     ENV['TWITTER_CONSUMER_SECRET']
end

### Helpers and utils

helpers do
  def logged_in
    !!session[:uid]
  end

  def r4s
    params[:r4s] == '1'
  end
end

def auth
  request.env['omniauth.auth']
end

def twitter
  Twitter::Client.new(
    consumer_key: ENV['TWITTER_CONSUMER_KEY'],
    consumer_secret: ENV['TWITTER_CONSUMER_SECRET'],
    oauth_token: session[:oauth_token],
    oauth_token_secret: session[:oauth_secret],
  )
end

def scan_id(s)
  s.scan(/^\s*@?([a-zA-Z0-9_]+)/).map {|a| a.first }
end

### Actions

get '/' do
  @default_ids = open('public/1000favs.txt', 'r').read
  slim :index
end

post '/block' do
  ids = scan_id(params[:ids])
  blocked_users = twitter.block(ids)
  s = blocked_users.size
  flash[:notice] = "You blocked #{s} user#{s == 1 ? '' : 's'}."
  redirect '/'
end

post '/r4s' do
  begin
    ids = scan_id(params[:ids])
    # reported_users = twitter.report_spam(ids) # Broken with twitter-4.3.0
    reported_users = twitter.send(:threaded_users_from_response, :post, '/1.1/users/report_spam.json', ids)
    s = reported_users.size
    flash[:notice] = "You reported #{s} user#{s == 1 ? '' : 's'} for spam."
  rescue Twitter::Error::NotFound
    flash[:alert] = 'Sorry, R4S mode is not working now.'
  rescue => e
    flash[:alert] = 'Unknown error occurred.' + e.inspect
  end
  redirect '/'
end

get '/lists/:name' do
  ids = []
  begin
    ids = scan_ids(open("public/#{params[:name]}.txt", 'r').read)
  rescue
    halt 404
  end
  content_type 'text/plain'
  body ids.join("\n")
end

get '/auth/twitter/callback' do
  session[:uid] = auth.uid
  session[:nickname] = auth.info.nickname
  session[:oauth_token] = auth.credentials.token
  session[:oauth_secret] = auth.credentials.secret
  redirect '/'
end

get '/logout' do
  session[:uid] = nil
  session[:nickname] = nil
  session[:oauth_token] = nil
  session[:oauth_secret] = nil
  redirect '/'
end
