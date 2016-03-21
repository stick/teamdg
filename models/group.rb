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
  end
end

class Group < Sequel::Model(:groups)

  def division
    self.name
  end

  def validate
    super
    validates_presence [:name]
  end
end

