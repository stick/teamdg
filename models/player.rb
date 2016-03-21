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
    Integer     :team_id, :null => false
    #unique      [:first_name, :last_name, :email_address]
  end
end

class Player < Sequel::Model(:players)
  # plugin :enum
  # enum :seed, [ :open1, :open2, :open3, :open4, :masters1, :masters2, :grandmasters, :woman, :amateur ]

  one_to_one :team

  def fullname
    return "#{self.first_name} #{self.last_name}"
  end

  def formalname
    return "#{self.last_name}, #{self.first_name}"
  end

  def validate
    super
    validates_presence [:name]
    validates_includes [ 'open1', 'open2', 'open3', 'open4', 'master1', 'master2', 'grandmaster', 'woman', 'amateur' ], :seed
  end
end

