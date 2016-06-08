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
    Integer     :wins, :default => 0, :null => false
    Integer     :losses, :default => 0, :null => false
    Integer     :ties, :default => 0, :null => false
    Integer     :no_decision, :default => 0, :null => false
    foreign_key :event_id, :events, :on_delete => :cascade, :null => false
    #unique      [:first_name, :last_name, :email_address]
  end
end

unless DB.table_exists?(:matches_teams)
  DB.create_join_table(team_id: :teams, match_id: :matches)
end

class Match < Sequel::Model(:matches)
  many_to_one :event
  many_to_many :teams
  one_to_many :games


  def validate
    super
    validates_presence [:desc]
  end
end

