# -*- coding: utf-8 -*-
=begin
all node names:
[ # 00 :method, :fbody, :cfunc, :scope, :block, :if, :case, :when, :opt_n, :while, # 10 :until, :iter, :for, :break, :next, :redo, :retry, :begin, :rescue, :resbody, # 20 :ensure, :and, :or, :not, :masgn, :lasgn, :dasgn, :dasgn_curr, :gasgn, :iasgn, # 30 :cdecl, :cvasgn, :cvdecl, :op_asgn1, :op_asgn2, :op_asgn_and, :op_asgn_or, :call, :fcall, :vcall, # 40 :super, :zsuper, :array, :zarray, :hash, :return, :yield, :lvar, :dvar, :gvar, # 50 :ivar, :const, :cvar, :nth_ref, :back_ref, :match, :match2, :match3, :lit, :str, # 60 :dstr, :xstr, :dxstr, :evstr, :dregx, :dregx_once, :args, :argscat, :argspush, :splat, # 70 :to_ary, :svalue, :block_arg, :block_pass, :defn, :defs, :alias, :valias, :undef, :class, # 80 :module, :sclass, :colon2, :colon3, :cref, :dot2, :dot3, :flip2, :flip3, :attrset, # 90 :self, :nil, :true, :false, :defined, # 95 :newline, :postexe, :alloca, :dmethod, :bmethod, # 100 :memo, :ifunc, :dsym, :attrasgn, :last

puste ify itd

=end

require 'set'
require 'experiment_node'
require 'experiment_processor'
require 'dag-tree'

class Tree
  attr_accessor :root

  def initialize(file)
    ep = ExperimentProcessor.new
    ep.analyze_file(file)
    @root = ep.tree
    @dependency_table = Hash.new { |hash, key| hash[key] = Array.new }
    set_orginal_names
    @overwritten_in_block = Hash.new { |hash, key| hash[key] = Array.new }
    eliminate_hiding
    find_expl_dependencies
    situate_grid_obj
    find_non_expl_dependencies
    find_dependencies_in_if_statement
    find_non_expl_dependencies
    # zbedne
    find_parallel_loops
    find_dependent_getresults
  end

  # updates 'orginal_name' field for all nodes which preserve original value of field name
  #
  def set_orginal_names(node = root)
    node.orginal_name = node.name
    node.sons.each { |son| set_orginal_names(son) }
  end

  # find parallel loops, updates fild parallel_loops for all nodes
  #
  def find_parallel_loops(node = root, loop_nodes = Array.new)
    if node.node_type == :iter and node.sons.first.node_type == :call and node.sons.first.name == "parallelFor"
      node.sons.each { |son|
        find_parallel_loops(son, loop_nodes.clone << node) if son.node_type == :block
      }
    else
      node.parallel_loops += loop_nodes
      node.sons.each { |son|
        find_parallel_loops(son, loop_nodes)
      }
    end
  end

  # finds dependencies between variables, for each node, it updates expl_dependencies array
  #
  def find_expl_dependencies(nodes = Array[root])
    nodes.each { |node|
      if [:lasgn, :attrasgn].include? node.node_type
        v = node.get_variable
        if v != []
          node.expl_dependencies += v
          @dependency_table[node.name] +=
            v.reject { |variable| variable.name == node.name}
        end
      elsif node.node_type == :lval
        node.expl_dependencies << node
      else
        find_expl_dependencies(node.sons)
      end
      if node.sons.first != nil and node.sons.first.node_type == :call
        node.sons.first.expl_dependencies += node.expl_dependencies
      end
    }
  end

  # updates grid_objects array for each node, it contains all gridobjects that are accesible from the considering node
  #
  def situate_grid_obj(nodes = Array[root], g_objs = Array.new)
    nodes.each do |node|
      g_objs << node if node.grid_obj?
      node.grid_objects += g_objs
      situate_grid_obj(node.sons, g_objs)
    end
  end

  # finds transive dependencies, for each node it updates non_expl_dependencies array
  #
  def find_non_expl_dependencies(node = root)
    variables = Array.new(node.expl_dependencies)
    until variables.empty? do
      v = variables.shift
      if not (node.expl_dependencies.names | node.non_expl_dependencies.names).include?(v.name)
        node.non_expl_dependencies << v
      end
      if @dependency_table.has_key?(v.name)
        variables += @dependency_table[v.name]
      end
    end
    node.sons.each {|s| find_non_expl_dependencies(s)}
  end

  # finds dependencies in 'if' constructs, for each node it updates expl_dependencies and dependencies_from_if_statement arrays
  #
  def find_dependencies_in_if_statement(node = root,
                                        if_statements_above = Array.new,
                                        loops_above = Array.new)
    node.expl_dependencies.each do |dependency|
      if @overwritten_in_block.has_key? dependency.name
        node.expl_dependencies += @overwritten_in_block[dependency.name]
        node.dependencies_from_if_statement += @overwritten_in_block[dependency.name]
      end
    end
    node.non_expl_dependencies.each do |dependency|
      if @overwritten_in_block.has_key? dependency.name
        node.non_expl_dependencies += @overwritten_in_block[dependency.name]
        node.dependencies_from_if_statement += @overwritten_in_block[dependency.name]
      end
    end

    node.loops_above += loops_above unless loops_above.empty?
    loops_above  << node if [:iter, :while, :for].include?(node.node_type)


    node.if_statements_above += if_statements_above unless if_statements_above.empty?
    if_statements_above << node if node.node_type == :if

    node.sons.each do |son|
      find_dependencies_in_if_statement(son, if_statements_above.clone, loops_above.clone)
    end
  end

  # updates dependent_getresults array for each node
  #
  def find_dependent_getresults(nodes = root.sons.clone)
    first = nodes.shift
    all_sons = Array.new(first.sons + nodes)
    all_sons += find_dependent_getresults(all_sons.clone) unless all_sons.empty?
    all_sons.each do |node_after|
      # jest wiele powtórzeń - poprawić (dlatego użyto |= a nie <<
      first.dependent_getresults |= [node_after] if
        node_after.expl_dependencies.names.include? first.name and
        node_after.is_get_result_on_active_object?
    end
    all_sons
  end

  # changes variable names if they repeat in a tree
  #
  def eliminate_hiding(nodes = root.sons.clone,
                       used_nodes = Array.new,
                       name_counter = Hash.new { |hash, key| hash[key] = 1 },
                       mode = :normal)
    first_node = nodes.shift
    if first_node.node_type == :if then
      first_node.sons.each do |son|
        eliminate_hiding([son],
                         used_nodes, name_counter, :if) if not first_node.sons.empty?
      end
    end
    if [:iter, :while, :for].include? first_node.node_type
      eliminate_hiding([first_node.sons.last],
                       used_nodes, name_counter, :iter) if not first_node.sons.empty?
    end
    if first_node.node_type == :block then
      eliminate_hiding(first_node.sons.clone,
                       used_nodes, name_counter, :block) if not first_node.sons.empty?
    end
    if first_node.node_type == :lasgn
      if used_nodes.names.include? first_node.name
        if [:if, :iter, :while, :block].include? mode then
          @overwritten_in_block[first_node.name] << first_node
        end
        new_name = "#{first_node.orginal_name}_#{name_counter[first_node.orginal_name]}"
        nodes.each { |node| modify_names(first_node.name, new_name, node) }
        first_node.name = new_name
        name_counter[first_node.orginal_name] += 1
      end
      used_nodes << first_node
    end

    eliminate_hiding(nodes, used_nodes, name_counter, mode) if not nodes.empty?
  end

  # changes all nodes named old_name to new_name in a whole subtree designated by node variable
  #
  def modify_names(old_name, new_name, node)
    node.name = new_name if node.name == old_name
    node.sons.each { |son| modify_names(old_name, new_name, son) }
  end

  # returns directed graph with dependencies between variables
  #
  def make_variables_dag(n = root, dag = DAG.new)
    # sprawdzic i opisac ten warunek
    if n.is_async_on_grid_obj? or n.is_get_result_on_active_object? or n.grid_obj?
      dag.name_unification[n.name] << n
      dependencies = (n.expl_dependencies.names +
                      n.non_expl_dependencies.names) & dag.nodes.keys
      dag.nodes[n.to_s] = dependencies if not dag.nodes.include?(n.to_s)
    end
    n.sons.each { |s|
      make_variables_dag(s, dag)
    }
    dag
  end

  # returns program's graph
  #
  def make_program_dag(n = root, dag = DAG.new)
    dag.sons[n] # zeby byl z pusta tablica
    n.sons.each { |son|
      dag.sons[n] << son
      make_program_dag(son, dag)
    }
    dag
  end

  # creates dependency graph between operations
  #
  def make_grid_operations_dag(n = root, dag = DAG.new)
    # sprawdzic i opisac ten warunek
    if n.is_async_on_grid_obj? or n.is_get_result_on_active_object?
      dag.name_unification[n.name] << n
      expl_dependencies = n.expl_dependencies.names & dag.expl_dependencies.keys
      dag.expl_dependencies[n.to_s] = expl_dependencies if not dag.expl_dependencies.include? n.to_s
      non_expl_dependencies = n.non_expl_dependencies.names & dag.non_expl_dependencies.keys
      dag.non_expl_dependencies[n.to_s] = non_expl_dependencies if not dag.non_expl_dependencies.include? n.to_s
    elsif n.grid_obj?
      dag.name_unification[n.name] << n
      dag.expl_dependencies[n.to_s] = Array.new
      dag.non_expl_dependencies[n.to_s] = Array.new
    end
    n.sons.each { |s|
      make_grid_operations_dag(s, dag)
    }
    dag
  end

  def get_dependencies_graph
    deps = get_dependencies
    DagTree.new(deps[:expl], deps[:non_expl],
                deps[:if_or_loop], deps[:name_unification])
  end

  def get_dependencies(n = root,
                       deps = {:expl => Hash.new,
                         :non_expl => Hash.new,
                         :if_or_loop => Hash.new,
                         :name_unification => Hash.new { |hash, key|
                           hash[key] = Array.new }})
    if n.is_async_on_grid_obj?
      deps[:name_unification][n.name] << n
      deps[:expl][n.to_s] = n.expl_dependencies.names &
        deps[:expl].keys if
        not deps[:expl].has_key? n.to_s
      deps[:non_expl][n.to_s] = n.non_expl_dependencies.names &
        deps[:non_expl].keys if
        not deps[:non_expl].has_key? n.to_s
      deps[:if_or_loop][n.to_s] =
        n.dependencies_from_if_statement.
        select {|node| node.is_async_on_grid_obj?}.names if
        not deps[:if_or_loop].has_key? n.to_s
    end
    n.sons.each do |s|
      get_dependencies(s, deps)
    end
    deps
  end
end
