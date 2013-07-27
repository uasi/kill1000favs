require 'bundler/setup'
Bundler.require *[:default, ENV['RACK_ENV']].compact

### Settings

enable :logging
enable :sessions

use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'],
                     ENV['TWITTER_CONSUMER_SECRET']
end

configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = File.expand_path("..", __FILE__)
end

configure :production do
  Pony.options = {
    :via => :smtp,
    :via_options => {
      :address => 'smtp.mandrillapp.com',
      :port => '587',
      :domain => 'heroku.com',
      :user_name => ENV['MANDRILL_USERNAME'],
      :password => ENV['MANDRILL_APIKEY'],
      :authentication => :plain,
      :enable_starttls_auto => true
    }
  }
end

# Twitter gem introduces Enumerable#threaded_map, which doesn't work well
# with threaded server like Puma.
# We replace that with Enumerable#map as a workaround.
class Array
  alias :threaded_map :map
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

### Filters

before do
  session[:locale] = params[:locale] if params[:locale]
end

### Actions

get '/' do
  @default_ids = open('public/1000favs.txt', 'r').read
  slim :index
end

def do_block(report = false)
  begin
    ids = scan_id(params[:ids]).uniq
    blocked_ids = Set.new(twitter.blocked_ids.ids)
    users = twitter.users(ids, include_entities: false)
    users.reject!(&:following) if params[:forgive_friends]
    blocked, to_block = users.partition {|u| blocked_ids.include?(u.id) }
    s = blocked.size
    to_block.map(&:screen_name).each_slice(100) do |sliced_ids|
      if report
        s += twitter.report_spam(*sliced_ids).size
      else
        s += twitter.block(*sliced_ids).size
      end
    end
    flash[:notice] = "You #{report ? 'reported' : 'blocked'} #{s} user#{s == 1 ? '' : 's'}."
  rescue Twitter::Error => e
    flash[:alert] = e.message + '.'
    if e.message =~ /You are over the limit/
      flash[:alert] += ' Try again later (15 minutes or more is good).'
    end
  end
  redirect '/'
end

post '/block' do
  do_block(false)
end

post '/r4s' do
  do_block(true)
end

get '/suggest' do
  slim :suggest
end

post '/suggest' do
  ids = []
  (1..5).each do |n|
    ids << params[:"id#{n}"] || ''
  end
  ids = ids.map {|id|
    id.strip =~ %r{^ (?: @ | https?://twitter\.com/(?:\#!/)? )? ([A-Za-z0-9_]+) (?: /.* )? $ }x
    $1
  }.compact.uniq
  if ids.size < 1
    flash[:alert] = t.enter_at_least_one_id
    redirect '/suggest'
  end
  id_list_items = ids.map {|id|
    url = 'https://twitter.com/' + id
    "<li><a href='#{url}'>#{url}</a></li>"
  }
  html_body = "<ul>#{id_list_items.join}</ul>"
  subject = 'Spam account suggestion by ' + (session[:nickname] || 'an anonymous')
  from = 'nobody@' + request.host
  Pony.mail(to: ENV['EMAIL'], from: from, subject: subject, html_body: html_body)
  flash[:notice] = t.sent_successfully
  redirect '/suggest'
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

error do
  'Internal Server Error'
end
