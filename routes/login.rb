#!/usr/bin/env ruby
#
#
# encoding: utf-8
class App < Sinatra::Base
  get "/login" do
    @title  = "Login"
    haml :login, layout: :'admin/layout'
  end

  post "/login" do
    if user = User.authenticate(params)
      session[:user] = user
      redirect_to_original_request
    else
      flash[:error] = 'You could not be signed in. Did you enter the correct username and password?'
      redirect '/login'
    end
  end

  get "/logout" do
    session[:user] = session[:pass] = nil
    flash[:notice] = 'You have been signed out.'
    redirect '/admin/'
  end
end
