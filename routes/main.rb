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
      roster_size: params[:roster_size].to_i
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
        [ 'open1', 'open2', 'open3', 'open4', 'master1', 'master2', 'grandmaster', 'woman', 'amateur' ].each do |seed|
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
    haml :teams
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

  post '/player/update/?' do
    player = Player.where(seed: params[:seed], team_id: params[:team_id]).first
    t = Team[params[:team_id]]
    if player.nil?
      t.add_player(name: params[:name], seed: params[:seed])
    else
      player.name = params[:name]
      player.seed = params[:seed]
      player.save
    end
  end
end
