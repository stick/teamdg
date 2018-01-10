#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sequel'

#Sequel::Model.plugin(:schema)

unless DB.table_exists? (:finalstages)
  DB.create_table :finalstages do
    primary_key :id
    String      :name, :null => false
    String      :captain, :null => false
    Bignum      :mobile_number
    String      :email_address
    #unique      [:first_name, :last_name, :email_address]
  end
end

class Finalstage < Sequel::Model(:finalstages)

  def validate
    super
    validates_presence [:name, :captain]
  end
end

