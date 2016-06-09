#!/usr/bin/env ruby
#
#
# encoding: utf-8
class App < Sinatra::Base
  get '/' do
    @title = "Main"
    haml :main, layout: true
  end

  get '/events/?' do
    haml :events
  end

  get '/event/new/?' do
    @title = 'New Event'
    haml :new_event
  end

  post '/event/new/?' do
    pp params
    e = Event.create(
      name: params[:event_name],
      event_type: params[:event_type],
      stage_1_format: params[:event_format1],
      stage_2_format: params[:event_format2],
      group_number: params[:event_group_num].to_i,
      group_advance: params[:event_group_advance].to_i,
      num_teams: params[:num_teams].to_i,
      roster_size: params[:roster_size].to_i,
      team_seeds: params[:team_seeds].split(/, /),
      cycles: params[:cycles].to_i || nil,
    )
    redirect to("/event/#{e.id}/setup")
  end

  get '/event/:id/setup/?' do
    @e = Event[params[:id]]
    @title = "#{@e.name} setup"
    haml :event_setup
  end

  post '/event/:id/setup/?' do
    pp params
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
    @schedule = RRSchedule::Schedule.new(
      teams: @event.groups.map { |group| @event.teams_dataset.where(group_id: group.id).map(:name) },
      rules: [
        RRSchedule::Rule.new(
          wday: 6,
          gt: [
            "09:00AM",
            "11:00AM",
            "01:00PM",
            "03:00PM",
          ],
          ps: [
            "Unitty Farm",
          ],
        ),
      ],
      start_date: Date.parse("2016/05/21"),
      cycles: 2,
      shuffle: false,
    )

    @schedule.generate

    puts @schedule.rounds.collect{ |r| r.to_s }

    # create db objects based on schedule
    @schedule.gamedays.each_with_index do |gd, matchnum|
      gd.games.each do |g|
        match = @event.add_match(
          desc: "Match #{matchnum + 1}",
          match_num: matchnum + 1,
          group_id: @event.teams_dataset.where(name: g.team_a.to_s).first.group_id,
          team_a: @event.teams_dataset.where(name: g.team_a.to_s).first.id,
          team_b: @event.teams_dataset.where(name: g.team_b.to_s).first.id,
        )
        match_id = match.id
        @event.team_seeds.each do |seed|
          @event.add_game(
            seed: seed,
            player_id_1: @event.teams_dataset.where(name: g.team_a.to_s).first.seed(seed).id,
            player_id_2: @event.teams_dataset.where(name: g.team_b.to_s).first.seed(seed).id,
            match_id: match_id,
          )
        end
      end
    end

    haml :set_schedule
  end

  get '/event/:event_id/teams/?' do
    @event = Event[params[:event_id]]
    haml :teams
  end

  get '/event/:event_id/groups/?' do
    @event = Event[params[:event_id]]
    haml :group_assignment
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
    @event = Event[params[:event_id]]
    @title = "#{@event.name}:settings"
    haml :event_settings
  end

  get '/team/:team_id/?' do
    @team = Team[params[:team_id]]
    pp @team
    haml :team
  end

  post '/team/:team_id/settings/update/?' do
    pp params
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
end
