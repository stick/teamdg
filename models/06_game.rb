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
    foreign_key :winner, :players, :on_delete => :cascade, :null => true
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
  many_to_many :teams
  many_to_many :players

  def player_a
    self.players.first
  end

  def player_b
    self.players.last
  end

  def after_update
    # update win/loss record for each match
    self.match.team_a_wins = self.match.games_dataset.where(winner: self.match.team_a.players_dataset.map(:id)).count
    self.match.team_a_losses = self.match.games_dataset.where(winner: self.match.team_b.players_dataset.map(:id)).count
    self.match.no_decisions = self.match.games_dataset.where(completed: nil).count
    self.match.team_a_ties = self.match.games_dataset.where(winner: nil).exclude(tie: nil).count
    self.match.save

    # update team point totals
    self.teams.each do |t|
      pp t
      wins = self.match.games_dataset.where(winner: t.players_dataset.map(:id)).count
      ties = self.match.games_dataset.exclude(tie: nil).count
      points = (t.event.matchpoints * wins) + (t.event.tiepoints * ties)
      t.points = points
      t.save
      pp "wins: #{wins}"
      pp "ties: #{ties}"
      pp "points: #{points}"
    end

  end

  def validate
    super
    validates_includes self.event.team_seeds, :seed
  end
end

