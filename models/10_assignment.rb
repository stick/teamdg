#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sequel'

unless DB.table_exists? (:assignments)
  DB.create_table :assignments do
    primary_key :id
    String      :reference, :null => false
    String      :info, :null => false
    foreign_key :event_id, :events, :on_delete => :cascade, :null => false
  end
end

class Assignment < Sequel::Model(:assignments)
  many_to_one :event

  def fetch(ref)
    return unless ref
    assignment = Assignment.where(event_id: self.event_id, reference: ref).first
    return "&nbsp;" if assignement.nil?
    return assignment.info unless assignment.nil?
  end

  def validate
    super
    validates_presence [:info, :reference]
  end
end
