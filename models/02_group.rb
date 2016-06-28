#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sequel'

Sequel::Model.plugin(:schema)

unless DB.table_exists? (:groups)
  DB.create_table :groups do
    primary_key :id
    String      :name, :null => false
    foreign_key :event_id, :events, :on_delete => :cascade, :null => false
  end
end

class Group < Sequel::Model(:groups)
  many_to_one :event
  one_to_many :teams
  one_to_many :matches
  one_to_many :players, :dataset => (
    proc do |r|
      r.associated_dataset.select_all(:players).join(Team, :teams__id => :team_id, id => [:group_id])
  end
  )

  def seed_winner(seed)
    return '' if seed.nil?
    self.players_dataset.where(seed: seed).sort_by{ |p| [ p.rr_wins, p.rr_ties, -p.rr_losses, p.rr_holes_up, p.rr_holes_remaining ] }.reverse
  end

  def seed_winners?
    self.players_dataset.association_join(:games).where(completed: true).count > 0 ? true : false
  end

  def rank
    case self.event.semis 
    when 'xgrouppoints', 'grouppoints'
      self.teams_dataset.select_append!{ rank{}.over(:order => [
        Sequel.expr(:points).desc,
        Sequel.expr(:holes_up).desc,
        Sequel.expr(:holes_remaining).desc,
      ]) }
    when 'points'
      self.event.teams_dataset.select_append!{ rank{}.over(:order => [
        Sequel.expr(:points).desc,
        Sequel.expr(:holes_up).desc,
        Sequel.expr(:holes_remaining).desc,
      ])}
    when 'record'
      # self.teams_dataset.order(Sequel.expr(:match_wins).desc, Sequel.expr(:match_losses), Sequel.expr(:match_ties).desc)
      self.teams_dataset.select_append!{ rank{}.over(:order => [
        Sequel.expr(:match_wins).desc,
        Sequel.expr(:match_losses),
        Sequel.expr(:match_ties).desc,
      ]) }
    else
      nil
    end
  end

  def seed_winners
    # self.players.sort_by{ |p| [ p.rr_wins, p.rr_ties, -p.rr_losses, p.rr_holes_up, p.rr_holes_remaining ] }.reverse.group_by{ |p| p.seed }
    sw = self.players_dataset.association_join(:games).where(completed: true)
    sw.select_append!{ rank{}.over(:order => [
      Sequel.expr(:players__rr_wins).desc,
      Sequel.expr(:players__rr_ties).desc,
      Sequel.expr(:players__rr_losses).asc,
      Sequel.expr(:players__rr_holes_up).desc,
      Sequel.expr(:players__rr_holes_remaining).desc,
    ], :partition => :players__seed) }
    sw2 = sw.group_by(:players__seed, :players__id).to_hash_groups(:seed)
    sw2
  end

  def winner
    self.teams_dataset.order(Sequel.expr(:points).desc, Sequel.expr(:holes_up), Sequel.expr(:holes_remaining)).to_a[0]
  end

  def runnerup
    self.teams_dataset.order(Sequel.expr(:points).desc, Sequel.expr(:holes_up), Sequel.expr(:holes_remaining)).to_a[1]
  end

  def size
    self.teams.size
  end

  def division
    self.name
  end

  def validate
    super
    validates_presence [:name]
  end
end

