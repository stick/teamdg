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
require 'ostruct'
require 'rrschedule'
require 'sinatra/asset_pipeline'

require_relative 'helpers/init'
require_relative 'models/init_console'
