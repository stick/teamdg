#!/usr/bin/env ruby
#
#
# encoding: utf-8
require 'sequel'

DB = Sequel.connect(ENV['DATABASE_URL'], max_connections: ENV['DB_POOL'] || 4) unless defined?(DB)

DB << "SET CLIENT_ENCODING TO 'UTF8';"

# load postgres specific extensions
DB.extension :pg_array
DB.extension :pg_enum
#DB.extension :pg_hstore

Sequel.default_timezone = :utc
Sequel.application_timezone = :local
Sequel::Model.plugin :validation_helpers
Sequel::Model.plugin :auto_validations
#Sequel::Model.plugin :contraint_validations

require_relative '01_event'
require_relative '02_group'
require_relative '03_team'
require_relative '04_player'
require_relative '05_match'
require_relative '06_game'
require_relative '07_groupstage'
require_relative '08_finalstage'

DB.disconnect
