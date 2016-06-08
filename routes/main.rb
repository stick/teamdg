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
      num_players: params[:num_players].to_i
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
