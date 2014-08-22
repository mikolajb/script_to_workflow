=begin
  * Name:
  * Description
  * Author: Mikolaj Baranowski, Krzysztof Nirski
  * Date:
  * License:
=end

require "rubygems"
require "bundler"
Bundler.setup

if ARGV.length < 2
  puts "Usage: ruby workflow.rb <experiment_file_name> <graph_type>"
  exit 0
end

file = File.open(ARGV[0]).read()

$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'set'
require 'experiment_tree'
require 'dag'

if ARGV[1] == "sexp"
  p RubyParser.new.parse(file)
  exit
end

t = Tree.new(file)

if ARGV[1] == "variables"
  puts t.make_variables_dag.variable_dependencies
elsif ARGV[1] == "program"
  puts t.make_program_dag.program
elsif ARGV[1] == "operations"
  puts t.make_grid_operations_dag.operation_dependencies
elsif ARGV[1] == "workflow"
  puts DAG.make_dependencies_dotgraph(t.get_dependencies_graph)
elsif ARGV[1] == "yaml"
  require 'yaml'
  puts t.get_dependencies_graph.to_yaml
end
