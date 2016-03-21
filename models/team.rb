#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sequel'

Sequel::Model.plugin(:schema)

unless DB.table_exists? (:teams)
  DB.create_table :teams do
    primary_key :id
    String      :name, :null => false
    String      :captain, :null => false
    Bignum      :mobile_number
    String      :email_address
    foreign_key :group_id, :groups, :null=>false, :on_delete => :cascade
    #unique      [:first_name, :last_name, :email_address]
  end
end

class Team < Sequel::Model(:teams)
  # Team Model
  one_to_many :players

  def group
    Group[self.group_id].name
  end

  def validate
    super
    validates_presence [:name, :captain]
  end
end

