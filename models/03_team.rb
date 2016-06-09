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

  def roster_size
    self.event.roster_size
  end

  def roster
    self.players.fullname
  end

  def seed(seed)
    self.players_dataset.where(seed: seed).first
  end

  def group
    if self.group_id.nil?
      nil
    else
      Group[self.group_id].name
    end
  end

  def after_create
    super
    self.event.team_seeds.each do |seed|
      self.add_player(seed: seed, name: seed)
    end
  end

  def validate
    super
    validates_presence [:name]
  end
end

