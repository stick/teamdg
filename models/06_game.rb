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
    #unique      [:first_name, :last_name, :email_address]
  end
end

unless DB.table_exists?(:games_teams)
  DB.create_join_table(team_id: :teams, game_id: :games)
end

unless DB.table_exists?(:games_players)
  DB.create_join_table(player_id: :players, game_id: :games)
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

  def validate
    super
    validates_includes self.event.team_seeds, :seed
  end
end

