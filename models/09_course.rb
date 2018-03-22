#!/usr/bin/env ruby
#
#

require 'rubygems'
require 'sequel'

unless DB.table_exists? (:courses)
  DB.create_table :courses do
    primary_key :id
    String      :name, :null => false
    String      :general_rules
    Integer     :course_size, :null => false, :default => 18
    column      :hole_names, 'text[]', :default => []
    column      :hole_nums, 'integer[]', :default => []
    column      :hole_distances, 'integer[]', :default => []
    column      :hole_pars, 'integer[]', :default => []
    column      :hole_rules, 'text[]', :default => []
    foreign_key :event_id, :events, :on_delete => :cascade, :null => false
  end
end

class Course < Sequel::Model(:courses)
  many_to_one :event

  def validate
    super
    validates_presence [:name]
  end

  def after_create
    need_save = false
    if self.hole_names.empty?
      self.hole_names = (1..self.course_size).map { |x| "Hole #{x}" }
      need_save = true
    end
    if self.hole_nums.empty?
      self.hole_nums = (1..self.course_size).map { |x| x }
      need_save = true
    end
    if self.hole_distances.empty?
      self.hole_distances = (1..self.course_size).map { |x| 100 }
      need_save = true
    end
    if self.hole_pars.empty?
      self.hole_pars = (1..self.course_size).map { |x| 2 }
      need_save = true
    end
    if self.hole_rules.empty?
      self.hole_rules = (1..self.course_size).map { |x| "Rule #{x}" }
      need_save = true
    end
    self.save if need_save
  end
end
