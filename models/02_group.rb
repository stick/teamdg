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
  one_to_many :players, :dataset => (
    proc do |r|
      r.associated_dataset.select_all(:players).join(Team, :id => :team_id, id => [:group_id])
  end
  )

  def seed_winner(seed)
    return '' if seed.nil?
    self.players_dataset.where(seed: seed).sort_by{ |p| p.rr_wins }.reverse
  end

  def seed_winners
    self.players.sort_by{ |p| p.rr_wins }.group_by{ |p| p.seed }
  end

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

