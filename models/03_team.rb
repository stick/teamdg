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
    String      :captain
    Bignum      :mobile_number
    String      :email_address
    Integer     :roster_size, :null => false, :default => 9
    foreign_key :event_id, :events, :on_delete => :cascade, :null => false
    foreign_key :group_id, :groups, :on_delete => :cascade
    unique      [:name, :event_id]
  end
end

class Team < Sequel::Model(:teams)
  # Team Model
  one_to_many :players
  many_to_one :event
  one_to_one :group

  def roster
    self.players.fullname
  end

  def group
    Group[self.group_id].name
  end

  def after_create
    super
    [ 'open1', 'open2', 'open3', 'open4', 'master1', 'master2', 'grandmaster', 'woman', 'amateur' ].each do |seed|
      self.add_player(seed: seed, name: seed)
    end
  end

  def validate
    super
    validates_presence [:name]
  end
end

