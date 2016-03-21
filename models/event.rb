#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sequel'

Sequel::Model.plugin(:schema)

unless DB.table_exists? (:events)
  DB.create_table :events do
    primary_key :id
    String      :name, :null => false
    #unique      [:first_name, :last_name, :email_address]
  end
end

class Event < Sequel::Model(:events)

  def validate
    super
    validates_presence [:name]
  end
end

