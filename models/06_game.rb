#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sequel'

Sequel::Model.plugin(:schema)

unless DB.table_exists? (:games)
  DB.create_table :games do
    primary_key :id
    foreign_key :event_id, :events, :on_delete => :cascade, :null => false
    String      :seed, :null => false
    # foreign_key :player_id_1, :players, :on_delete => :cascade, :null => false
    # foreign_key :player_id_2, :players, :on_delete => :cascade, :null => false
    foreign_key :winner_id, :players, :on_delete => :cascade, :null => true
    foreign_key :match_id, :matches, :on_delete => :cascade, :null => false
    Integer     :holes_up, :default => 0, :null => false
    Integer     :holes_remaining, :default => 0, :null => false
    TrueClass   :sudden_death, :default => false, :null => false
    FalseClass  :completed, :default => false
    Integer     :tie
    #unique      [:first_name, :last_name, :email_address]
  end
end

unless DB.table_exists?(:games_teams)
  DB.create_table :games_teams do
    foreign_key :team_id, :teams, on_delete: :cascade, null: false
    foreign_key :game_id, :games, on_delete: :cascade, null: false
    primary_key [:team_id, :game_id]
    index [:team_id, :game_id]
  end
end

unless DB.table_exists?(:games_players)
  DB.create_table :games_players do
    foreign_key :player_id, :players, on_delete: :cascade, null: false
    foreign_key :game_id,  :games, on_delete: :cascade, null: false
    primary_key [:player_id, :game_id]
    index [:player_id, :game_id]
  end
end

class Game < Sequel::Model(:games)
  many_to_one :event
  many_to_one :match
  many_to_many :teams, :order => :teams__id
  many_to_many :players, :order => :players__id
  one_to_one :winner, :class => self do |ds|
    self.players_dataset.where(id: self.winner_id)
  end

  def player_a
    self.players.first
  end

  def player_b
    self.players.last
  end

  def result(id, tiny=nil)
    if self.completed
      if tiny
        return '<span class="label label-default col-sm-12">T</span>' unless self.tie.nil?
        return "<span class='label label-success col-sm-12'>W" if id == self.winner_id
        return "<span class='label label-danger col-sm-12'>L" if id != self.winner_id
      else
        return '<span class="label label-default col-sm-12">Tied</span>' unless self.tie.nil?
        return "<span class='label label-success col-sm-12'>W #{self.holes_up} &amp; #{self.holes_remaining}</span>" if id == self.winner_id
        return "<span class='label label-danger col-sm-12'>L #{self.holes_up} &amp; #{self.holes_remaining}</span>" if id != self.winner_id
      end
    end
    ''
  end

  def after_update
    # update win/loss record for each match
    self.match.team_a_wins = self.match.games_dataset.where(winner_id: self.match.team_a.players_dataset.map(:id)).count
    self.match.team_a_losses = self.match.games_dataset.where(winner_id: self.match.team_b.players_dataset.map(:id)).count
    self.match.team_a_ties = self.match.games_dataset.where(completed: true).exclude(tie: nil).count
    self.match.no_decisions = self.match.games_dataset.where(completed: nil).count
    if self.match.decided
      self.match.winner_id = self.match.winner.id
    end
    self.match.save

    self.players.each do |p|
      p.update_stats
    end

    # update team point totals
    self.teams.each do |t|
      t.update_points
    end

  end

  def showdown
    "#{self.player_a.name} <small>#{self.player_a.team.name}</small> #{vs} #{self.player_b.name} <small>#{self.player_b.team.name}</small>"
  end

  def validate
    super
    validates_includes self.event.team_seeds, :seed
  end
end

