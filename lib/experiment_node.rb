# -*- coding: utf-8 -*-
class Array
  def names
    map { |node| node.name }
  end
end

class Node
  attr_accessor :sons, :parent,
  :name, :node_type, :grid_objects,
  :expl_dependencies, :non_expl_dependencies,
  # zbedne
  :parallel_loops,
  :dependent_getresults, :orginal_name,
  :dependencies_from_if_statement,
  :if_statements_above, :loops_above

  def initialize(name = 'node')
    @name = name
    @sons = Array.new
    @node_type = :main
    # contains an array of grid objects that are visible in node
    @grid_objects = Array.new
    # all dependencies
    @expl_dependencies = Array.new
    # transitive dependencies
    @non_expl_dependencies = Array.new
    # dependencies from the if statement
    @dependencies_from_if_statement = Array.new
    # zbedne
    @parallel_loops = Array.new
    @dependent_getresults = Array.new
    @if_statements_above = Array.new
    @loops_above = Array.new
  end

  def to_s
    return name.to_s
  end

  # returns an array with :lval nodes located at the lower layer or one element array with a node on which this operation was performed (if :lval)
  #
  def get_variable
    result = Array.new
    if @node_type == :lval
      result << self
    else
      result += @sons.map { |s| s.get_variable }
    end

    return result.flatten
  end

  # checks if node is a grid object initialization
  #
  def grid_obj?
    return (@node_type == :lasgn and !@sons.select {|s| s.node_type == :call and !s.sons.select {|ss| ss.node_type == :const and ss.name == "GObj"}.empty? }.empty?)
  end

  # checks if node is grid object instance
  #
  def grid_operation?
    grid_operation_checker(self) or
      (not @sons.empty? and grid_operation_checker(@sons.first))
  end

  # returns true if 'candidate' is grid object instance and there is an operation executed on it
  #
  def grid_operation_checker(candidate)
    candidate.node_type == :call and
      candidate.sons.first.node_type == :lval and
      (candidate.grid_objects.map {|g_obj| g_obj.name}).include? candidate.sons.first.name
  end

  # checks if there is a grid object used in a branch
  #
  def depend_of_gobj?
    result = !(@grid_objects.map {|g_obj| g_obj.name} & @non_expl_dependencies.map {|n| n.name}).empty? or
      not (@grid_objects.map {|g_obj| g_obj.name} & @expl_dependencies.map {|n| n.name}).empty? or
      not @sons.select {|s| s.depend_of_gobj?}.empty?
  end

  # checks if the node is grid_operation?, its name starts from "async" and it does not start with "get_result"
  #
  def is_async_on_grid_obj?
    grid_operation? and sons.any? { |s| s.name.start_with? "async" } and not name.start_with? "get_result"
  end

  # checks if "get_result" is invoked
  #
  def is_get_result_on_active_object?
    (node_type == :lasgn and
     not sons.empty? and
     not ((expl_dependencies.map { |n| n.name } + non_expl_dependencies.map { |n| n.name }) & grid_objects.map { |n| n.name }).empty? and
     (sons.first.name.start_with? "get_result" or (not sons.first.sons.empty? and sons.first.sons.first.name.start_with? "get_result")))  # x.get_result and x.get_result.foo()
  end

  # returns list of arguments for :call node and returns nil for other types
  #
  def get_arg_list
    return nil if node_type != :call

    sons.each do |son|
      if son.node_type == :arglist
        return son.sons.map {|arg| arg.name}.join(', ')
      end
    end

    return nil
  end
end
