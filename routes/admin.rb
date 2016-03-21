#!/usr/bin/env ruby
#
#
require 'csv'

class App < Sinatra::Base

  get '/admin/?' do
    @title = 'RUG::Admin'
    haml :'admin/index', :layout => :'admin/layout'
  end

end
