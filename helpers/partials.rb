#!/usr/bin/env ruby
#
#
# encoding: utf-8
def spoof_request(uri,env_modifications={})
  call(env.merge("PATH_INFO" => uri).merge(env_modifications)).last.join
end

def partial( page, variables={} )
  haml page, {layout:false}, variables
end

def dropdown_navbar( items )
  partial(:_dropdown_navbar_items, { items: items })
end
