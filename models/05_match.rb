#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sequel'

Sequel::Model.plugin(:schema)

unless DB.table_exists? (:matches)
  DB.create_table :matches do
    primary_key :id
    String      :desc
    Integer     :match_num
    foreign_key :winner, :teams, :on_delete => :cascade, :null => true
    # foreign_key :team_a, :teams, :on_delete => :cascade, :null => true
    # foreign_key :team_b, :teams, :on_delete => :cascade, :null => true
    foreign_key :group_id, :groups, :on_delete => :cascade, :null => false
    Integer     :team_a_wins, :default => 0, :null => false
    Integer     :team_a_losses, :default => 0, :null => false
    Integer     :team_a_ties, :default => 0, :null => false
    Integer     :no_decisions, :default => 0, :null => false
    Integer     :day, :default => 6, :null => false
    foreign_key :event_id, :events, :on_delete => :cascade, :null => false
    #unique      [:first_name, :last_name, :email_address]
  end
end

unless DB.table_exists?(:matches_teams)
  DB.create_table :matches_teams do
    foreign_key :team_id, :teams, on_delete: :cascade, null: false
    foreign_key :match_id,  :matches, on_delete: :cascade, null: false
    primary_key [:team_id, :match_id]
    index [:team_id, :match_id]
  end
end

class Match < Sequel::Model(:matches)
  many_to_one :event
  many_to_many :teams
  one_to_many :games
  many_to_one :group

  def team_b_wins
    self.team_a_losses
  end

  def team_b_losses
    self.team_a_wins
  end

  def team_b_ties
    self.team_a_ties
  end

  def team_b_nods
    self.team_a_nds
  end

  def team_a
    self.teams.first
  end

  def team_a_players
    self.teams.first.players
  end

  def team_b_players
    self.teams.last.players
  end

  def team_b
    self.teams.last
  end

  def validate
    super
    validates_presence [:desc]
  end
end

