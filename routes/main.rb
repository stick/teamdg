#!/usr/bin/env ruby
#
#
# encoding: utf-8
class App < Sinatra::Base
  get '/' do
    haml :main, layout: false
  end
end
