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
    Integer     :rr_wins
    Integer     :rr_losses
    Integer     :rr_ties
    Integer     :rr_holes_up
    Integer     :rr_holes_remaining
    Integer     :elim_wins
    Integer     :elim_losses
    Integer     :elim_ties
    foreign_key :team_id, :teams, :on_delete => :cascade, :null => false
    foreign_key :event_id, :events, :one_delete => :cascade, :null => false
    #unique      [:first_name, :last_name, :email_address]
  end
end

class Player < Sequel::Model(:players)
  many_to_one :team
  many_to_many :games, :order => :games__id
  many_to_many :matches, :order => :matches__id
  many_to_one :event

  def record
    wins = self.rr_wins + self.elim_wins
    losses = self.rr_losses + self.elim_losses
    ties = self.rr_ties + self.elim_ties
    return "#{wins} &mdash; #{losses} &mdash; #{ties}"
  end

  def update_stats
    self.rr_wins = self.games_dataset.where(completed: true, winner_id: self.id, sudden_death: false).count
    self.rr_losses = self.games_dataset.where(completed: true, sudden_death: false).exclude(winner_id: self.id).count
    self.rr_ties = self.games_dataset.where(completed: true, sudden_death: false).exclude(tie: nil).count
    self.elim_wins = self.games_dataset.where(winner_id: self.id, sudden_death: true).count
    self.elim_losses = self.games_dataset.where(completed: true, sudden_death: true).exclude(winner_id: self.id).count
    self.elim_ties = self.games_dataset.where(completed: true, sudden_death: true).exclude(tie: nil).count
    self.rr_holes_up = self.games_dataset.where(completed: true, winner_id: self.id, sudden_death: false).map(:holes_up).sum
    self.rr_holes_remaining = self.games_dataset.where(completed: true, winner_id: self.id, sudden_death: false).map(:holes_remaining).sum
    self.save
  end

  def elim_record
    return "#{self.elim_wins} &mdash; #{self.elim_losses} &mdash; #{self.elim_ties}"
  end

  def rr_record
    return "#{self.rr_wins} &mdash; #{self.rr_losses} &mdash; #{self.rr_ties}"
  end

  def validate
    super
    validates_presence [:name]
    validates_includes self.team.event.team_seeds, :seed
  end
end

