#!/usr/bin/env ruby
#
#
# encoding: utf-8
class App < Sinatra::Base

  get '/?' do
    redirect to('/dashboard')
  end

  get '/dashboard/?' do
    @title = "Dashboard"
    haml :main, layout: true
  end

  get '/events/?' do
    @title = "Events"
    haml :events
  end

  get '/event/new/?' do
    @title = 'New Event'
    haml :new_event
  end

  post '/event/new/?' do
    pp "New Event Creation: "
    pp params
    group_advance = case params[:event_group_num].to_i
                    when 4 then 1
                    when 2 then 2
                    when 1 then 4
                    else nil
                    end

    e = Event.create(
      name: params[:event_name],
      event_type: params[:event_type],
      stage_1_format: params[:event_format1],
      stage_2_format: params[:event_format2],
      group_number: params[:event_group_num].to_i,
      group_advance: group_advance,
      num_teams: params[:num_teams].to_i,
      roster_size: params[:roster_size].to_i,
      team_seeds: params[:team_seeds].split(/, /),
      cycles: params[:cycles].to_i || nil,
      startdate: params[:event_startdate],
      enddate: params[:event_enddate],
    )
    redirect to("/event/#{e.id}/setup")
  end

  get '/event/:id/setup/?' do
    @e = Event[params[:id]]
    @title = "#{@e.name} setup"
    haml :event_setup
  end

  post '/event/:id/setup/?' do
    e = Event[params[:id]]
    # create groups based on event
    (1..e.group_number).each do |g|
      e.add_group(name: "group_#{g}")
    end

    # create teams
    params[:team_name].each do |team|
      e.add_team(name: team)
    end
    redirect to("/event/#{params[:id]}/")
  end

  get_or_post '/event/:event_id/start/?' do
    @event = Event[params[:event_id]]

    # if the event is schedule short circuit so we don't create extra matches/games/teams
    if @event.scheduled
      redirect to("/event/#{@event.id}/scheduled")
    else
      @event.scheduled = true
      @event.save && @event.refresh
    end

    @schedule = RRSchedule::Schedule.new(
      teams: @event.groups.map { |group| group.teams.map { |t| t.name } },
      rules: [
        RRSchedule::Rule.new( wday: 6, gt: [ "09:00AM", "11:00AM", "01:00PM" ], ps: [ "Unitty Farm", ]),
        RRSchedule::Rule.new( wday: 0, gt: [ "09:00AM" ], ps: [ "Unitty Farm", ]),
      ],
      start_date: @event.startdate,
      cycles: @event.cycles,
      shuffle: false,
    )

    @schedule.generate

    @schedule.rounds.each do |round|
      round.each do |match_by_round|
        match_by_round.games.each do |team_match|
          pp match_by_round.inspect
          match = @event.add_match(
            desc: "Match #{match_by_round.round_with_cycle}",
            match_num: match_by_round.round_with_cycle,
            group_id: @event.teams_dataset.where(name: team_match.team_a.to_s).first.group_id,
            day: 0
          )
          match.add_team(@event.teams_dataset.where(name: team_match.team_a.to_s).first)
          match.add_team(@event.teams_dataset.where(name: team_match.team_b.to_s).first)
          @event.team_seeds.each do |seed|
            game = match.add_game( seed: seed, event_id: @event.id,)
            game.add_team(@event.teams_dataset.where(name: team_match.team_a.to_s).first)
            game.add_team(@event.teams_dataset.where(name: team_match.team_b.to_s).first)
            game.add_player(@event.teams_dataset.where(name: team_match.team_a.to_s).first.seed(seed))
            game.add_player(@event.teams_dataset.where(name: team_match.team_b.to_s).first.seed(seed))
          end
        end
      end
    end
    redirect to("/event/#{@event.id}/matches/event")
  end

  get '/event/:event_id/scheduled/?' do
    @event = Event[params[:event_id]]
    haml :event_scheduled
  end

  get '/event/:event_id/matches/event/?' do
    @event = Event[params[:event_id]]
    @title= "#{@event.name}:Event Matches"
    haml :event_matches
  end

  get '/event/:event_id/matches/delete/?' do
    @event = Event[params[:event_id]]
    @event.matches.map { |m| m.destroy }
    @event.teams.map { |t| t.update_points }
    @event.players.map { |p| p.update_stats }
    @event.scheduled = false
    @event.save
    redirect to("/event/#{@event.id}/")
  end

  get '/event/:event_id/games/?' do
    @event = Event[params[:event_id]]
    haml :event_games
  end

  [
    '/event/:event_id/matches/group/match/:match_id/?',
    '/event/:event_id/matches/event/match/:match_id/?',
    '/event/:event_id/matches/team/:team_id/match/:match_id/?',
    '/event/:event_id/match/:match_id/?'
  ].each do |path|
    get path do
      @match = Match[id: params[:match_id], event_id: params[:event_id]]
      @event = Event[params[:event_id]]
      haml :event_match
    end
  end

  get '/event/:event_id/game/:game_id/?' do
    @game = Game[id: params[:game_id], event_id: params[:event_id]]
    @event = Event[params[:event_id]]
    @match = @game.match
    haml :event_game
  end

  get '/event/:event_id/match/:match_id/game/:game_id/?' do
    haml :match_game
  end

  get '/event/:event_id/team/?' do
    redirect to("/event/#{params[:event_id]}/team/all")
  end

  get '/event/:event_id/team/all?' do
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:Teams"
    haml :teams
  end

  get '/event/:event_id/groups/?' do
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:Group assignment"
    haml :group_assignment
  end

  post '/event/:event_id/game/:game_id/?' do
    pp params
    game = Game[params[:game_id]]
    if params[:winner_id] == 'tie'
      game.tie = 1
      game.winner_id = nil
      game.holes_up = 0
      game.holes_remaining = 0
    else
      player = Player[params[:winner_id]]
      pp player
      pp player.team
      game.winner_id = params[:winner_id].to_i
      game.holes_up = params[:holes_up].to_i
      game.holes_remaining = params[:holes_remaining].to_i
      game.tie = nil
    end
    game.completed = true
    game.save
    redirect back
  end

  get '/event/:event_id/game/:game_id/tie/?' do
    pp params
    game = Game[params[:game_id]]
    game.winner_id = nil
    game.holes_up = 0
    game.holes_remaining = 0
    game.tie = 1
    game.completed = true
    game.save
    redirect back
  end

  get '/event/:event_id/game/:game_id/reset/?' do
    game = Game[params[:game_id]]
    game.winner_id = nil
    game.tie = nil
    game.completed = false
    game.save
    redirect back
  end

  get '/event/:event_id/assign_groups/ordered/?' do
    @event = Event[params[:event_id]]
    unassigned_teams = @event.teams_dataset.where(group_id: nil).all
    teams_per_group = unassigned_teams.size / @event.group_number
    split_teams = unassigned_teams.each_slice(teams_per_group).to_a
    split_teams.each_with_index do |group, index|
      group.each do |team|
        egroup = @event.groups[index]
        egroup.add_team(team)
      end
    end
    redirect back
  end

  get '/event/:event_id/assign_groups/reset/?' do
    @event = Event[params[:event_id]]
    @event.teams.map{ |t| t.group_id = nil; t.save }
    redirect back
  end

  get '/event/:event_id/assign_groups/shuffled/?' do
    @event = Event[params[:event_id]]
    unassigned_teams = @event.teams_dataset.where(group_id: nil).all.shuffle
    teams_per_group = unassigned_teams.size / @event.group_number
    split_teams = unassigned_teams.each_slice(teams_per_group).to_a
    split_teams.each_with_index do |group, index|
      group.each do |team|
        egroup = @event.groups[index]
        egroup.add_team(team)
      end
    end
    redirect back
  end

  get '/event/:event_id/delete/?' do
    Event[params[:event_id]].destroy
    redirect to('/events/')
  end

  get '/event/:event_id/?' do
    redirect to("/event/#{params[:event_id]}/settings")
  end

  get '/event/:event_id/settings/?' do
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:settings"
    haml :event_settings
  end

  get '/team/:team_id/?' do
    @team = Team[params[:team_id]]
    redirect to("/event/#{@team.event.id}/team/#{@team.id}")
  end

  get '/event/:event_id/team/:team_id/?' do
    @event = Event[params[:event_id]]
    @team = Team[params[:team_id]]
    @title = "#{@event.name}:#{@team.name}"
    haml :team
  end

  post '/team/:team_id/settings/update/?' do
    t = Team[params[:team_id]]
    t.send("#{params[:setting]}=", params[:value])
    t.save
  end

  post '/team/:team_id/update/?' do
    t = Team[params[:team_id]]
    t.group_id = params[:group_id].to_i
    t.save
  end

  post '/group/:group_id/update/?' do
    g = Group[params[:group_id]]
    g.name = params[:group_name]
    g.save
  end

  post '/event/:event_id/update/?' do
    e = Event[params[:event_id]]
    if params[:update] == 'semis'
      e.group_advance = case params[:value]
      when 'points', 'record' then 4
      else 2
      end
    end
    e.send("#{params[:update]}=", params[:value])
    e.save
  end

  get '/event/:event_id/schedule/?' do
    @event = Event[params[:event_id]]
    haml :event_schedule
  end

  post '/player/:player_id/update/?' do
    player = Player[params[:player_id]]
    t = player.team
    if player.nil?
      t.add_player(name: params[:name], seed: params[:seed])
    else
      player.name = params[:name]
      player.seed = params[:seed]
      player.save
    end
  end

  get '/event/:event_id/rosters/?' do
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:Rosters"
    haml :rosters
  end

  get '/event/:event_id/matches/group/?' do
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:Group Matches"
    haml :group_matches
  end

  get '/event/:event_id/matches/team/?' do
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:Team Matches"
    haml :team_matches
  end

  get '/event/:event_id/matches/team/:team_id/?' do
    @event = Event[params[:event_id]]
    @team = Team[params[:team_id]]
    @title = "#{@event.name}:Team Matches:#{@team.name}"
    haml :team_match
  end

  get '/event/:event_id/matches/player/?' do
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:Player Matches"
    haml :player_matches
  end

  get '/event/:event_id/matches/player/:player_id/?' do
    @event = Event[params[:event_id]]
    @player = Player[params[:player_id]]
    @title = "#{@event.name}:Player Matches:#{@player.name}"
    haml :player_match
  end

  get '/event/:event_id/standings/?' do
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:Standings"
    haml :event_standings
  end

  get '/event/:event_id/matches/games/unreported/?' do
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:Unreported Matches"
    haml :games_unreported
  end

  get '/event/:event_id/elimination/?' do
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:Elimination"

    if @event.elim_matches.count < 1 and @event.rr_matches_completed >= 100
      match_num = @event.matches_dataset.max(:match_num) + 1
      m = @event.add_match(match_num: match_num, desc: 'Elimination', elim: true, day: 0)
      bottoms = []
      @event.groups.each do |group|
        bottoms.push group.rank.where(exempt: false).reverse.to_a.first
      end
      team_a = bottoms.shift
      team_b = bottoms.shift
      m.add_team(team_a)
      m.add_team(team_b)
      @event.team_seeds.each do |seed|
        pp "creating game for match 1 - seed #{seed}"
        g = m.add_game( seed: seed, event_id: @event.id, sudden_death: true)
        g.add_team(team_a)
        g.add_team(team_b)
        g.add_player(team_a.seed(seed))
        g.add_player(team_b.seed(seed))
      end
    else
      @match = @event.elim_matches.first
    end
    haml :event_elimination
  end

  get '/event/:event_id/elimination/delete/?' do
    @event = Event[params[:event_id]]
    @event.elim_matches.each { |m| m.destroy }
    redirect to("/event/#{@event.id}/standings")
  end

  get '/event/:event_id/semifinals/?' do
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:Semifinals"

    if @event.semi_matches.count < 1 and @event.rr_matches_completed >= 100
      match_num = @event.matches_dataset.max(:match_num) + 1
      m1 = @event.add_match(match_num: match_num, desc: 'Semifinals Match 1', semi: true, day: 0)
      m2 = @event.add_match(match_num: match_num, desc: 'Semifinals Match 2', semi: true, day: 0)
      case @event.semis
      when 'xgrouppoints'
        m1.add_team(@event.groups.first.winner)
        m1.add_team(@event.groups.last.runnerup)

        m2.add_team(@event.groups.last.winner)
        m2.add_team(@event.groups.first.runnerup)
      when 'grouppoints'
        m1.add_team(@event.groups.first.winner)
        m1.add_team(@event.groups.first.runnerup)
        m2.add_team(@event.groups.last.winner)
        m2.add_team(@event.groups.last.runnerup)
      when 'points'
        sorted_teams = @event.groups.first.rank.to_a
        m1.add_team(sorted_teams.shift) # leader
        m2.add_team(sorted_teams.shift) # runner up
        m2.add_team(sorted_teams.shift) # 3rd
        m1.add_team(sorted_teams.shift) # 4th
      when 'xgrouprecord'
        gr1_sorted_teams = @event.groups.first.rank.to_a
        gr2_sorted_teams = @event.groups.last.rank.to_a
        m1.add_team(gr1_sorted_teams.shift)
        m2.add_team(gr2_sorted_teams.shift)
        m1.add_team(gr2_sorted_teams.shift)
        m2.add_team(gr1_sorted_teams.shift)
      when 'grouprecord'
        gr1_sorted_teams = @event.groups.first.rank.to_a
        gr2_sorted_teams = @event.groups.last.rank.to_a
        m1.add_team(gr1_sorted_teams.shift)
        m1.add_team(gr1_sorted_teams.shift)
        m2.add_team(gr2_sorted_teams.shift)
        m2.add_team(gr2_sorted_teams.shift)
      when 'record'
        sorted_teams = @event.groups.first.rank.to_a
        m1.add_team(sorted_teams.shift)
        m2.add_team(sorted_teams.shift)
        m2.add_team(sorted_teams.shift)
        m1.add_team(sorted_teams.shift)
      else
        puts "fallthrough case"
        halt haml :invalid_event
      end
      @event.team_seeds.each do |seed|
        pp "creating game for match 1 - seed #{seed}"
        g1 = m1.add_game( seed: seed, event_id: @event.id, sudden_death: true)
        # incorrect teams and possibly players for other schemes FIXME
        g1.add_team(@event.groups.first.winner)
        g1.add_team(@event.groups.last.runnerup)
        g1.add_player(@event.groups.first.winner.seed(seed))
        g1.add_player(@event.groups.last.runnerup.seed(seed))

        pp "creating game for match 2 - seed #{seed}"
        g2 = m2.add_game( seed: seed, event_id: @event.id, sudden_death: true)
        g2.add_team(@event.groups.last.winner)
        g2.add_team(@event.groups.first.runnerup)
        g2.add_player(@event.groups.last.winner.seed(seed))
        g2.add_player(@event.groups.first.runnerup.seed(seed))
      end
    end

    haml :event_semifinals
  end

  get '/event/:event_id/semifinals/delete/?' do
    @event = Event[params[:event_id]]
    @event.semi_matches.each { |m| m.destroy }
    redirect to("/event/#{@event.id}/standings")
  end

  get '/event/:event_id/finals/?' do
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:Finals"

    if @event.final_matches.count > 0
      @match = @event.final_matches.first
    else
      if @event.semi_matches.map(:winner_id).compact.size == 2
        match_num = @event.matches_dataset.max(:match_num) + 1
        @match = @event.add_match(match_num: match_num, desc: 'Finals', final: true, day: 0)
        # add the semi winners to the final match
        @event.semi_matches.each { |m| @match.add_team(m.winner) }
        @event.team_seeds.each do |seed|
          game = @match.add_game(seed: seed, event_id: @event.id, sudden_death: true)
          @event.semi_matches.each { |m| game.add_team(m.winner) }
          @event.semi_matches.each { |m| game.add_player(m.winner.seed(seed)) }
        end
      end
    end
    haml :event_finals
  end

  get '/event/:event_id/finals/delete/?' do
    @event = Event[params[:event_id]]
    @event.final_matches.each { |m| m.destroy }
    redirect to("/event/#{@event.id}/semifinals")
  end

  get '/:event_slug/match/:match_id/?' do
    @event = Event[url: CGI::unescape(params[:event_slug])]
    if @event.nil?
      haml :missing_event, layout: :layout_no_sidebar, locals: { hide_breadcrumbs: true }
    else
      # @player = @event.players_dataset.where(name: CGI::unescape(params[:player_name])).first
      @title = @event.name
      @match = Match[params[:match_id]]
      if @match.nil?
        haml :missing_match, layout: :layout_no_sidebar, locals: { hide_breadcrumbs: true }
      else
        @public = true
        haml :event_match, layout: :layout_no_sidebar, locals: { hide_breadcrumbs: true }
      end
    end
  end

  get '/:event_slug/player/:player_name/?' do
    @event = Event[url: CGI::unescape(params[:event_slug])]
    if @event.nil?
      haml :missing_event, layout: :layout_no_sidebar, locals: { hide_breadcrumbs: true }
    else
      @title = @event.name
      @player = @event.players_dataset.where(name: CGI::unescape(params[:player_name])).first
      @public = true
      if @player.nil?
        haml :missing_player, layout: :layout_no_sidebar, locals: { hide_breadcrumbs: true }
      else
        haml :player_match, layout: :layout_no_sidebar, locals: { hide_breadcrumbs: true }
      end
    end
  end

  get '/:event_slug/team/:team_name/?' do
    @event = Event[url: CGI::unescape(params[:event_slug])]
    if @event.nil?
      haml :missing_event, layout: :layout_no_sidebar, locals: { hide_breadcrumbs: true }
    else
      @team = @event.teams_dataset.where(name: CGI::unescape(params[:team_name])).first
      @title = @event.name
      @public = true
      if @team.nil?
        haml :missing_team, layout: :layout_no_sidebar, locals: { hide_breadcrumbs: true }
      else
        haml :team_match, layout: :layout_no_sidebar, locals: { hide_breadcrumbs: true }
      end
    end
  end

  get '/:event_slug/?' do
    @event = Event[url: CGI::unescape(params[:event_slug])]
    if @event.nil?
      haml :missing_event, layout: :layout_no_sidebar, locals: { hide_breadcrumbs: true }
    else
      @title = @event.name
      @public = true
      haml :event_standings, locals: { hide_breadcrumbs: true }, layout: :layout_no_sidebar
    end
  end

end
