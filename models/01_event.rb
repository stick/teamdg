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
    String      :event_type, :null => false, :default => 'two_stage'
    String      :stage_1_format
    String      :stage_2_format
    Integer     :group_number, :default => 1, :null => false
    Integer     :group_advance, :default => 1, :null => false
    Integer     :num_teams, :null => false
    Integer     :roster_size, :null => false
    Integer     :matchpoints, :null => false, :default => 3
    Integer     :cycles
    Integer     :tiepoints, :null => false, :default => 1
    String      :semis, :null => false, :default => 'xgrouppoints'
    Date        :startdate
    Date        :enddate
    column      :team_seeds, 'text[]'

    #unique      [:first_name, :last_name, :email_address]
  end
end

class Event < Sequel::Model(:events)
  one_to_many :teams
  one_to_many :groups
  one_to_many :matches
  one_to_many :games
  def validate
    super
    validates_presence [:name]
  end

  def matches_by_order
    # output an array of arrays of the matches by order they are played
    # 4 matches are played simulataneously for an 8 team RR
    # something like: [[a v b],[c v d], [e v f],[g v h]]
  end

  def matches_by_team
    # output matches by teams
  end

  def after_create
    pp self.team_seeds
    pp self.team_seeds.empty?
    if self.team_seeds.empty?
      self.team_seeds = (1..self.roster_size).map { |x| x }
      self.save
    end
  end
end

