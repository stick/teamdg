require 'rubygems'
require 'bundler'

Bundler.require

$stdout.sync = true
root = ::File.dirname(__FILE__)
require ::File.join( root, 'app' )
use Rack::Deflater
run App.new
