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
    foreign_key :winner_id, :teams, :on_delete => :cascade, :null => true
    # foreign_key :team_a, :teams, :on_delete => :cascade, :null => true
    # foreign_key :team_b, :teams, :on_delete => :cascade, :null => true
    foreign_key :group_id, :groups, :on_delete => :cascade, :null => true
    Integer     :team_a_wins, :default => 0, :null => false
    Integer     :team_a_losses, :default => 0, :null => false
    Integer     :team_a_ties, :default => 0, :null => false
    Integer     :no_decisions, :default => 0, :null => false
    Integer     :day, :default => 6, :null => false
    Integer     :tie, :null => true
    TrueClass   :completed, :default => false
    TrueClass   :semi, :default => false
    TrueClass   :final, :default => false
    TrueClass   :elim, :default => false
    String      :info
    foreign_key :event_id, :events, :on_delete => :cascade, :null => false
    #unique      [:first_name, :last_name, :email_address]
  end
end

unless DB.table_exists?(:matches_teams)
  DB.create_table :matches_teams do
    foreign_key :team_id, :teams, on_delete: :cascade, null: false
    foreign_key :match_id,  :matches, on_delete: :cascade, null: false
    primary_key [:team_id, :match_id]
    index [:team_id, :match_id]
  end
end

# unless DB.table_exists?(:matches_players)
  # DB.create_table :matches_players do
    # foreign_key :player_id, :players, on_delete: :cascade, null: false
    # foreign_key :match_id,  :matches, on_delete: :cascade, null: false
    # primary_key [:player_id, :match_id]
    # index [:player_id, :match_id]
  # end
# end

class Match < Sequel::Model(:matches)
  many_to_one :event
  many_to_many :teams, :order => [ :teams__rr_rank, :teams__id ] 
  one_to_many :games, :order => :games__id
  many_to_one :group



  def showdown(record: false)
    if record
      return "#{self.team_a.name} <strong color='text-success'>#{self.team_a_wins}</strong> <small><em>vs</em></small> #{self.team_b.name} <strong class='text-success'>#{self.team_b_wins}</strong>"
    end
    return "#{self.team_a.name} <small><em>vs</em></small> #{self.team_b.name}"
  end

  def showdown_score(winner: false)
    html = "<span class='fa-stack'>#{icon('square-o', size: 'stack-2x', ex_classes: 'text-success')}<strong class='fa-stack-1x'>#{ winner ? self.winner_score : self.team_a_wins }</strong></span>"
    html += "#{icon('minus')}"
    html += "<span class='fa-stack'>#{icon('square-o', size: 'stack-2x', ex_classes: 'text-success')}<strong class='fa-stack-1x'>#{ winner ? self.loser_score : self.team_b_wins }</strong></span>"
    return html
  end

  def holes_up(team)
    self.games_dataset.where(winner_id: team.players_dataset.map(:id), completed: true, sudden_death: false).map(:holes_up).sum
  end

  def holes_remaining(team)
    self.games_dataset.where(winner_id: team.players_dataset.map(:id), completed: true, sudden_death: false).map(:holes_remaining).sum
  end

  def team_b_wins
    self.team_a_losses
  end

  def team_b_losses
    self.team_a_wins
  end

  def team_b_ties
    self.team_a_ties
  end

  def team_b_nods
    self.team_a_nds
  end

  def team_a
    self.teams.first
  end

  def team_a_players
    self.teams.first.players
  end

  def team_b_players
    self.teams.last.players
  end

  def team_b
    self.teams.last
  end

  def record(team)
    if self.team_a == team
      [
        self.team_a_wins,
        self.team_a_losses,
        self.team_a_ties,
      ]
    elsif self.team_b == team
      [
        self.team_b_wins,
        self.team_b_losses,
        self.team_b_ties,
      ]
    else
      [ nil, nil, nil ]
    end
  end

  def points(team)
    if self.team_a == team
      self.team_a_points
    elsif self.team_b == team
      self.team_b_points
    else
      -1000
    end
  end

  def team_b_points
    (self.team_b_wins * self.event.matchpoints) + (self.team_b_ties * self.event.tiepoints)
  end

  def team_a_points
    (self.team_a_wins * self.event.matchpoints) + (self.team_a_ties * self.event.tiepoints)
  end

  def decided
    if self.semi or self.final or self.elim
      majority = (self.event.roster_size / 2.0).round
      if (self.team_a_wins >= majority ) or (self.team_a_losses >= majority)
        true
      else
        false
      end
    else
       self.no_decisions > 0 ? false : true
    end
  end

  def result
    if self.completed
      if self.winner
        { result: 'winner', winner: self.winner, loser: self.loser, score: "#{self.winner_score} - #{self.loser_score}" }
      elsif self.tie
        { result: 'tie', score: "#{self.team_a_wins} - #{self.team_b_wins}" }
      else
        { result: 'problem', score: 'impossible' }
      end
    end
  end

  def winner_score
    if self.semi or self.final or self.elim
      majority = (self.event.roster_size / 2.0).round
      return self.team_a_wins if self.team_a_wins >= majority
      return self.team_b_wins if self.team_b_wins >= majority
    else
      if self.no_decisions <= 0
        return self.team_a_wins if self.team_a_wins > self.team_b_wins
        return self.team_b_wins if self.team_b_wins > self.team_a_wins
      end
    end
  end

  def loser_score
    if self.semi or self.final or self.elim
      majority = (self.event.roster_size / 2.0).round
      return self.team_b_wins if self.team_a_wins >= majority
      return self.team_a_wins if self.team_b_wins >= majority
    else
      if self.no_decisions <= 0
        return self.team_b_wins if self.team_a_wins >= self.team_b_wins
        return self.team_a_wins if self.team_b_wins >= self.team_a_wins
      end
    end
  end

  def winner
    if self.semi or self.final or self.elim
      majority = (self.event.roster_size / 2.0).round
      return self.team_a if self.team_a_wins >= majority
      return self.team_b if self.team_b_wins >= majority
    else
      if self.no_decisions <= 0
        return self.team_a if self.team_a_wins > self.team_b_wins
        return self.team_b if self.team_b_wins > self.team_a_wins
      end
    end
  end

  def loser
    majority = (self.event.roster_size / 2.0).round
    return self.team_b if self.team_a_wins >= majority
    return self.team_a if self.team_b_wins >= majority
  end

  def when
    case self.match_num
    when 1 then "Session 1 #{Date::DAYNAMES[self.day]} Morning"
    when 2 then "Session 2 #{Date::DAYNAMES[self.day]} Morning"
    when 3 then "Session 3 #{Date::DAYNAMES[self.day]} Afternoon"
    when 4 then "Session 4 #{Date::DAYNAMES[self.day]} Afternoon"
    when 5 then "Session 5 #{Date::DAYNAMES[self.day]} Morning"
    when 6 then "Session 6 #{Date::DAYNAMES[self.day]} Morning"
    else
      "Session unknown -- #{Date::DAYNAMES[self.day]} whenever"
    end
  end

  def validate
    super
    validates_presence [:desc]
  end
end

