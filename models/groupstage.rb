#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sequel'

Sequel::Model.plugin(:schema)

unless DB.table_exists? (:groupstage)
  DB.create_table :groupstage do
    primary_key :id
    Integer :round
    Integer :home_team_id
    Integer :away_team_id
    Integer :group
  end
end

class Groupstage < Sequel::Model(:groupstage)


  def validate
    super
  end
end

