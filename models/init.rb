#!/usr/bin/env ruby
#
#
# encoding: utf-8
require 'sequel'

DB = Sequel.connect(ENV['DATABASE_URL'], max_connections: ENV['DB_POOL'] || 4) unless defined?(DB)

DB << "SET CLIENT_ENCODING TO 'UTF8';"
# load postgres specific extensions
DB.extension :pg_array
DB.extension :pg_hstore

Sequel.default_timezone = :utc
Sequel.application_timezone = :local
Sequel::Model.plugin :validation_helpers

require_relative 'event'
require_relative 'team'
require_relative 'player'
require_relative 'group'
require_relative 'groupstage'
require_relative 'finalstage'

DB.disconnect
