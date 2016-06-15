#!/usr/bin/env ruby
#
#
# encoding: utf-8
require_relative 'partials'
#require_relative 'display'
#require_relative 'auth'
#
def vs
  haml "%small <em>vs</em>"
end

def icon(name='empire', fw=false, size=nil)
  iconsize = size.nil? ? '' : ".fa-#{size}"
  fixedwidth = '.fa-fw' if fw
  haml "%i.fa#{fixedwidth}.fa-#{name}#{iconsize}"
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
