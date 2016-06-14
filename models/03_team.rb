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
    Integer     :points
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
  many_to_many :matches
  many_to_many :games

  def roster_size
    self.event.roster_size
  end

  def roster
    self.players.map(:name)
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

  def add_to_group(group)
    Group[group.id].add_team(self)
  end

  def after_create
    super
    i = 1
    self.event.team_seeds.each do |seed|
      pp "adding player (player #{i}) as seed (#{seed}) to #{self.name}"
      self.add_player(seed: seed, name: "#{self.name} Player #{i}")
      i += 1
    end
  end

  def validate
    super
    validates_presence [:name]
  end
end

