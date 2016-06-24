#!/usr/bin/env ruby
#
#
# encoding: utf-8
require_relative 'partials'
#require_relative 'display'
#require_relative 'auth'
#
def vs
  "<small><em>vs</em></small>"
end

def icon(name='empire', fw: false, size: nil, ex_classes: [], id: nil, tooltip: nil)
  classes = [ 'fa', "fa-#{name}" ]
  classes.push('fa-fw') if fw
  classes.push("fa-#{size}") if size
  classes.push(ex_classes) unless ex_classes.empty?
  element_id = "id='#{id}' " if id
  tooltip_attr = "data-toggle='tooltip' data-title='#{tooltip}' " if tooltip
  "<i #{tooltip_attr}#{element_id}class='#{classes.flatten.join(' ')}'></i>"
end

def result_list_class(game, player)
  if game.completed
    return 'list-group-item-info' if game.tie
    return 'list-group-item-success' if game.winner == player.id
    return 'list-group-item-danger' if game.winner != player.id
  end
end

def result(game, player)
  if game.completed
    return 'tie' if game.tie
    return 'win' if game.winner == player.id
    return 'loss' if game.winner != player.id
  end
end

def format_record(record, tiny: false, color: false)
  # [ wins, losses, ties ] / { wins: x, losses: y, ties: z }
  if record.is_a?(Hash)
    return record.values.join('/') if tiny
    return "<span class='text-success'>#{record[:wins]}</span> &mdash; <span class='text-danger'>#{record[:losses]}</span> &mdash; <span class='text-muted'>#{record[:ties]}</span>" if color
    return record.values.join(' &mdash; ')
  elsif record.is_a?(Array)
    return record.join('/') if tiny
    return "<span class='text-success'>#{record[0]}</span> &mdash; <span class='text-danger'>#{record[1]}</span> &mdash; <span class='text-muted'>#{record[2]}</span>" if color
    return record.join(' &mdash; ')
  else
    "shoo"
  end
end

def ordinalize(i)
  case i
  when 1
    "#{i}<sup>st</sup>"
  when 2
    "#{i}<sup>nd</sup>"
  when 3
    "#{i}<sup>rd</sup>"
  else
    "#{i}<sup>th</sup>"
  end
end
