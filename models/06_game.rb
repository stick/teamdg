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
    foreign_key :player_id_1, :players, :on_delete => :cascade, :null => false
    foreign_key :player_id_2, :players, :on_delete => :cascade, :null => false
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

class Game < Sequel::Model(:games)
  many_to_one :event
  many_to_one :match
  many_to_many :teams


  def validate
    super
    validates_includes [ 'open1', 'open2', 'open3', 'open4', 'master1', 'master2', 'grandmaster', 'woman', 'amateur' ], :seed
  end
end

