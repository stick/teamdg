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
    Integer     :holes_up
    Integer     :holes_remaining
    Integer     :rr_wins
    Integer     :rr_losses
    Integer     :rr_ties
    Integer     :elim_wins
    Integer     :elim_losses
    Integer     :elim_ties
    foreign_key :event_id, :events, :on_delete => :cascade, :null => false
    foreign_key :group_id, :groups, :on_delete => :cascade
    unique      [:name, :event_id]
  end
end

class Team < Sequel::Model(:teams)
  # Team Model
  one_to_many :players, :order => :players__id
  many_to_one :event
  one_to_one :group
  many_to_many :matches, :order => :matches__id
  many_to_many :games, :order => :games__id

  def roster_size
    self.event.roster_size
  end

  def roster
    self.players.map(:name)
  end

  def seed(seed)
    self.players_dataset.where(seed: seed).first
  end

  def opponents
    opp_teams = []
    self.matches.each do |match|
      match.teams.each do |team|
        opp_teams.push(team) unless team.id == self.id
      end
    end
    return opp_teams
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
      self.add_player(seed: seed, name: "#{self.name} Player #{i}", event_id: self.event.id)
      i += 1
    end
  end

  def update_points
    rr_wins = self.games_dataset.where(completed: true, sudden_death: false, winner_id: self.players_dataset.map(:id)).count
    rr_ties = self.games_dataset.where(completed: true, sudden_death: false).exclude(tie: nil).count
    self.rr_wins = rr_wins
    self.rr_losses = self.games_dataset.where(completed: true, sudden_death: false).exclude(winner_id: self.players_dataset.map(:id)).count
    self.rr_ties = rr_ties
    self.elim_wins = self.games_dataset.where(completed: true, sudden_death: true, winner_id: self.players_dataset.map(:id)).count
    self.elim_losses = self.games_dataset.where(completed: true, sudden_death: true).exclude(winner_id: self.players_dataset.map(:id)).count
    self.elim_ties = self.games_dataset.where(completed: true, sudden_death: true).exclude(tie: nil).count
    self.points = (rr_wins * self.event.matchpoints ) + (rr_ties * self.event.tiepoints)
    self.holes_up = self.games_dataset.where(winner_id: self.players_dataset.map(:id), completed: true, sudden_death: false).map(:holes_up).sum
    self.holes_remaining = self.games_dataset.where(winner_id: self.players_dataset.map(:id), completed: true, sudden_death: false).map(:holes_remaining).sum
    self.save
  end

  def validate
    super
    validates_presence [:name]
  end
end

