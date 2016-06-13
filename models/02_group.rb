#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sequel'

Sequel::Model.plugin(:schema)

unless DB.table_exists? (:groups)
  DB.create_table :groups do
    primary_key :id
    String      :name, :null => false
    foreign_key :event_id, :events, :on_delete => :cascade, :null => false
  end
end

class Group < Sequel::Model(:groups)
  many_to_one :event
  one_to_many :teams
  one_to_many :matches

  def size
    self.teams.size
  end

  def division
    self.name
  end

  def validate
    super
    validates_presence [:name]
  end
end

