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
    foreign_key :team_id, :teams, :on_delete => :cascade, :null => false
    foreign_key :event_id, :events, :one_delete => :cascade, :null => false
    #unique      [:first_name, :last_name, :email_address]
  end
end

class Player < Sequel::Model(:players)
  many_to_one :team
  many_to_many :games
  many_to_many :matches
  many_to_one :event

  def record
    return "#{self.rr_wins} &mdash; #{self.rr_losses} &mdash; #{self.rr_ties}"
  end

  def rr_record
    return "#{self.rr_wins} &mdash; #{self.rr_losses} &mdash; #{self.rr_ties}"
  end

  def rr_wins
    self.games_dataset.where(winner: self.id).count
  end

  def rr_losses
    self.games_dataset.where(completed: true).exclude(winner: self.id).count
  end

  def rr_ties
    self.games_dataset.where(completed: true).exclude(tie: nil).count
  end

  def validate
    super
    validates_presence [:name]
    validates_includes self.team.event.team_seeds, :seed
  end
end

