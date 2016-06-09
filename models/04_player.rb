#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sequel'

Sequel::Model.plugin(:schema)

unless DB.table_exists? (:players)
  DB.create_table :players do
    primary_key :id
    String      :name, :null => false
    Bignum      :mobile_number
    String      :email_address
    String      :seed, :null => false
    foreign_key :team_id, :teams, :on_delete => :cascade, :null => false
    #unique      [:first_name, :last_name, :email_address]
  end
end

class Player < Sequel::Model(:players)

  many_to_one :team

  def fullname
    return "#{self.first_name} #{self.last_name}"
  end

  def formalname
    return "#{self.last_name}, #{self.first_name}"
  end

  def validate
    super
    validates_presence [:name]
    validates_includes self.team.event.team_seeds, :seed
  end
end

