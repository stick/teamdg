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

