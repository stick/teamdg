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
    Integer     :group_number, :default => 2, :null => false
    Integer     :group_advance, :default => 2, :null => false
    Integer     :num_teams, :null => false, :default => 8
    Integer     :roster_size, :null => false, :default => 9
    Integer     :matchpoints, :null => false, :default => 3
    Integer     :cycles, :default => 2
    Integer     :tiepoints, :null => false, :default => 1
    String      :url, :unique => true
    TrueClass   :scheduled, :default => false
    String      :semis, :null => false, :default => 'xgrouppoints'
    Date        :startdate
    Date        :enddate
    column      :team_seeds, 'text[]', :default => []

    #unique      [:first_name, :last_name, :email_address]
  end
end

class Event < Sequel::Model(:events)
  one_to_many :teams, :order => :teams__id
  one_to_many :groups, :order => :groups__id
  one_to_many :matches, :order => :matches__id
  one_to_many :games, :order => :games__id
  one_to_many :players, :order => :players__id

  def validate
    super
    validates_presence [:name]
    validates_unique [:url]
  end

  def rr_matches_completed
    (self.games_dataset.where(completed: true, sudden_death: false).count.to_f / self.games.count.to_f * 100.0).to_i
  end

  def rr_incomplete
    self.games_dataset.where(completed: false, sudden_death: false).count
  end

  def matches_by_order
    # output an array of arrays of the matches by order they are played
    # 4 matches are played simulataneously for an 8 team RR
    # something like: [[a v b],[c v d], [e v f],[g v h]]
  end

  def matches_by_team
    # output matches by teams
  end

  def semi_matches
    self.matches_dataset.where(semi: true)
  end

  def semi_games
  end

  def final_matches
    self.matches_dataset.where(final: true)
  end

  def final_games
  end

  def after_create
    if self.team_seeds.empty?
      self.team_seeds = (1..self.roster_size).map { |x| x }
      self.save
    end
  end
end

