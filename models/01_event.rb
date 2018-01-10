#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sequel'

#Sequel::Model.plugin(:schema)

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
    String      :group_decider, :null => false, :default => 'points'
    TrueClass   :scheduled, :default => false
    TrueClass   :elimination_match, :default => false
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

  def rr_matches?
    self.games_dataset.where(sudden_death: false).count > 0 ? true : false
  end

  def rr_matches_completed
    ratio = self.games_dataset.where(completed: true, sudden_death: false).count.to_f / self.games_dataset.where(sudden_death: false).count.to_f * 100.0
    ratio.nan? ? 0 : ratio.to_i
  end

  def rr_matches_completed?
    if self.rr_matches_completed >= 100
      true
    else
      false
    end
  end

  def elim_matches_completed?
    a_results = []
    self.elim_matches.each { |m| a_results.push m.decided }
    a_results.select{ |x| !x }.empty?
  end

  def elim_matches
    self.matches_dataset.where(elim: true)
  end

  def elim_matches?
    self.elim_matches.count > 0
  end

  def rr_incomplete
    self.games_dataset.where(completed: false, sudden_death: false).count
  end

  def semi_matches
    self.matches_dataset.where(semi: true)
  end

  def semi_matches?
    self.semi_matches.count > 0
  end

  def semi_matches_complete?
    a_results = []
    self.semi_matches.each { |m| a_results.push m.decided }
    a_results.select{ |x| !x }.empty?
  end

  def match_rounds
    (self.num_teams / self.group_number) - 1
  end

  def group_matches
    (self.num_teams / self.group_number) / 2
  end

  def semi_games
  end

  def final_matches
    self.matches_dataset.where(final: true)
  end

  def final_matches?
    self.final_matches.count > 0
  end

  def final_matches_complete?
    a_results = []
    if self.final_matches.count > 0
      self.final_matches.each { |m| a_results.push m.decided }
      a_results.select{ |x| !x }.empty?
    else
      false
    end
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

