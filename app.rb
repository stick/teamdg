#!/usr/bin/env ruby
#
#

require 'dotenv'
Dotenv.load

require 'pp'
require 'pg'
require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'sinatra/streaming'
require 'sinatra/flash'
require 'sequel'
require 'haml'
require 'logger'
require 'rest-client'
require 'ostruct'
require 'round_robin_tournament'
require 'rrschedule'

require_relative 'helpers/init'
require_relative 'models/init'

class App < Sinatra::Base
  register Sinatra::ConfigFile
  helpers Sinatra::Streaming
  config_file './config.yml'

  configure :development do
    register Sinatra::Reloader
    enable :logging
    enable :show_exceptions
    set :force_ssl, false
  end

  configure :test do
    enable :logging
    enable :show_exceptions
    set :force_ssl, false
  end

  configure :production do
    set :force_ssl, false
    require 'newrelic_rpm'
  end

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
  end

  use Rack::Session::Cookie,
    httponly: true,
    key: 'rack.session',
    path: '/admin',
    expire_after: 2592000, # 1 month
    secret: ENV['SESSION_SECRET']

  ##use Rack::GoogleAnalytics, :tracker => 'UA-68537168-1'

  configure do
  end

  register Sinatra::Flash

  before do
    redirect request.url.sub('https', 'http') if request.secure?
  end

  before '/admin/?*' do
    authenticate!
  end

  # allow a route called get_or_post to handle both
  def self.get_or_post(url,&block)
    get(url,&block)
    post(url,&block)
  end

  error do
    haml :'500', layout: :basic_bs_layout
  end
  # required inside the class so pathing works out correctly
  require_relative 'routes/init'

end


