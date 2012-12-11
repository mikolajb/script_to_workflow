require 'dag-node'
require 'dag-edge'

class DagTree
  attr_accessor :edges, :nodes

  def initialize(expl_dependencies = nil,
                 non_expl_dependencies = nil,
                 dependencies_from_if_statement = nil,
                 name_unification = nil)
    @edges = Array.new
    @nodes = Array.new
    @if_statements = Hash.new
    @loop_statements = Hash.new

    if expl_dependencies == nil and non_expl_dependencies == nil and
        dependencies_from_if_statement == nil and name_unification == nil
      return
    end

    dag_node_hash = Hash.new
    (expl_dependencies.keys | non_expl_dependencies.keys).each do |node_name|
      dag_node_hash[node_name] =
        add_node_and_unification(node_name,
                                 name_unification[node_name])
    end

    Hash[:expl => expl_dependencies,
         :non_expl => non_expl_dependencies,
         :if_or_loop => dependencies_from_if_statement].each do |dep_kind, dep_dict|
      dep_dict.each do |target, roots|
        roots.each do |root|
          add_edge(dag_node_hash[root], dag_node_hash[target],
                   dep_kind.to_sym)
        end
      end
    end
    remove_duplicates
    expand_loops
  end

  def add_edge(node1, node2, type = :normal)
    experiment_node1 = node1.program_nodes.first
    experiment_node2 = node2.program_nodes.first
    deps = experiment_node1.dependent_getresults.names &
      experiment_node2.expl_dependencies.names

    from = node1
    loop_statements = node2.loop_statements - node1.loop_statements
    if_statements = node2.if_statements - node1.if_statements
    loop_statement_ends = node1.loop_statements - node2.loop_statements
    if_statement_ends = node1.if_statements - node2.if_statements

    if not (loop_statement_ends.empty? and if_statement_ends.empty?)
      type = :exit
    end

    (loop_statements + if_statements + [node2]).each do |target|
      to = target
      if [:if, :loop, :p_loop].include? from.type
        add_to_edges(from, to, deps, :non_expl)
      else
        add_to_edges(from, to, deps, type)
      end
      from = to
    end
  end

  def add_to_edges(from, to, deps, type)
    return if connection_exists(from, to) and deps.empty?
    @edges.each do |edge|
      if edge.from == from and edge.to == to
        edge.deps.concat(deps).uniq!
        return
      end
    end
    @edges << DagEdge.new(from, to, deps.clone, type)
  end

  def connection_exists(from, to, exception = nil)
    return true if from == to
    @edges.each do |edge|
      next if edge == exception or edge.type == :if_or_loop
      if from == edge.from
        return true if connection_exists(edge.to, to)
      end
    end
    false
  end

  def remove_duplicates
    @edges.reject! do |edge|
      connection_exists(edge.from, edge.to, edge)
    end
  end

  def add_node(node_name)
    @nodes << DagNode.new(node_name)
    @nodes.last
  end

  def add_node_and_unification(node_name, name_unification)
    node = add_node(node_name)
    node.program_nodes = name_unification

    node.program_nodes.first.if_statements_above.each do |if_statement|
      if @if_statements.has_key? if_statement
        node.if_statements << @if_statements[if_statement].first
      else
        dag_if_node = DagNode.new('if', :if)
        dag_if_node.program_nodes = [if_statement]
        dag_if_node.condition = dag_if_node.get_condition
        @if_statements[if_statement] = [dag_if_node, if_statement]
        @nodes << dag_if_node
        node.if_statements << dag_if_node
      end
    end

    node.program_nodes.first.loops_above.each do |loop_statement|
      if @loop_statements.has_key? loop_statement
        node.loop_statements << @loop_statements[loop_statement].first
      else
        if loop_statement.sons.first.node_type == :call and
            loop_statement.sons.first.name == "parallelFor"
          dag_loop_node = DagNode.new('parallelFor', :p_loop)
        else
          dag_loop_node = DagNode.new('loop', :loop)
        end
        dag_loop_node.program_nodes = [loop_statement]
        dag_loop_node.condition = dag_loop_node.get_condition
        @loop_statements[loop_statement] = [dag_loop_node, loop_statement]
        @nodes << dag_loop_node
        node.loop_statements << dag_loop_node
      end
    end

    node
  end

  def expand_loops
    new_edges = Array.new
    new_nodes = Array.new
    edges_to_remove = Array.new
    @edges.each do |edge|
      if [:p_loop, :loop].include? edge.from.type
        loopback = nil
        3.times do |i|
          edges_to_proc = Array[edge]
          node_from = edge.from
          exits = Array.new
          while proc_edge = edges_to_proc.shift
            if proc_edge.type == :exit
              exits << proc_edge.clone
              exits.last.from = node_from
              next
            elsif proc_edge.type == :if_or_loop
              loopback = proc_edge.clone
              loopback.from = node_from
              new_edges << loopback
              edges_to_remove << proc_edge
              next
            end

            new_nodes << proc_edge.to.clone
            new_nodes.last.name += "__loop#{i}"
            loopback.to = new_nodes.last if loopback and
              proc_edge.to == loopback.to

            new_edges << proc_edge.clone
            new_edges.last.from = node_from
            new_edges.last.to = new_nodes.last
            node_from = new_nodes.last

            @edges.each do |edge_candidate|
              if edge_candidate.from == proc_edge.to
                edges_to_proc << edge_candidate
              end
            end
          end

          exits.each do |exit|
            new_edges << exit
          end
        end
      end
    end
    @edges += new_edges
    @edges -= edges_to_remove
    @nodes += new_nodes
  end

  def to_yaml
    output_hash = Hash.new

    output_nodes = Hash.new
    @nodes.each do |node|
      output_nodes[node.hash] = Hash.new
      input = Array.new
      output = Array.new
      @edges.each do |edge|
        output << edge.hash if edge.from == node
        input << edge.hash if edge.to == node
      end
      output_nodes[node.hash]['input'] = input
      output_nodes[node.hash]['output'] = output
      output_nodes[node.hash]['name'] = node.get_name
      output_nodes[node.hash]['type'] = node.type.to_s
      if node.type == :if then
        output_nodes[node.hash]['condition'] = node.condition
      elsif [:loop, :p_loop].include? node.type
        output_nodes[node.hash]['condition'] = node.condition
      end
    end
    output_hash['nodes'] = output_nodes

    output_edges = Hash.new
    @edges.each do |edge|
      output_edges[edge.hash] = Hash.new
      output_edges[edge.hash]['type'] = edge.type.to_s
      output_edges[edge.hash]['deps'] = edge.deps.join(', ')
    end
    output_hash['edges'] = output_edges

    output_hash.to_yaml
  end
end
