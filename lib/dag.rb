require 'experiment_node'
require 'graphviz'

class DAG
  attr_accessor :nodes,   # adjacency list variable_dependencies
  :expl_dependencies, # used in workflow
  :non_expl_dependencies, # used in workflow
  :sons, # used in operation_dependencies
  :name_unification # used in workflow

  def initialize()
    @nodes = Hash.new
    @expl_dependencies = Hash.new
    @non_expl_dependencies = Hash.new
    @sons = Hash.new { |hash, key| hash[key] = Array.new }
    @name_unification = Hash.new { |hash, key| hash[key] = Array.new }
  end

  def variable_dependencies
    g = GraphViz::new('variables')
    g.node[:fontname] = 'Inconsolata'
    node_hash = Hash.new

    nodes.each { |key, value|
      new_node = g.add_nodes(key)
      new_node[:label] = key
      node_hash[key] = new_node
    }
    nodes.each { |key, value|
      value.each { |k|
        g.add_edges(node_hash[k], node_hash[key])
      }
    }
    g.output :none => String
  end

  def program
    g = GraphViz::new('full')
    g.node[:fontname] = 'Inconsolata'
    g[:ordering] = 'out'
    node_hash = Hash.new
    sons.keys.each { |node|
      label = "#{node.name.delete("<").delete("\n").delete(">").delete("\"")}|type #{node.node_type}\\l" +
      "gridobjects #{node.grid_objects.join(", ")}\\l" +
      "direct dependencies: #{node.expl_dependencies.join(", ")}\\l" +
      "transitive dependencies: #{node.non_expl_dependencies.join(", ")}\\l" +
      # zbedne
      # "parallel_loops #{node.parallel_loops.join(", ")}\\l" +
      "deps from block: #{node.dependencies_from_if_statement.join(", ")}\\l" +
      "if statements: #{node.if_statements_above.join(", ")}\\l" +
      "iters: #{node.loops_above.join(", ")}\\l" +
      "dependent operation handlers: #{node.dependent_getresults.join(", ")}\\l"

      new_node = g.add_nodes(node.__id__.to_s)
      new_node[:shape] = 'Mrecord'
      new_node[:label] = label
      node_hash[node.__id__] = new_node
    }
    sons.each { |node, dependencies|
      dependencies.each { |node2|
        g.add_edges(node_hash[node.__id__], node_hash[node2.__id__])
      }
    }
    g.output :none => String
  end

  def operation_dependencies
    g = GraphViz::new("callgraph")
    g.node[:fontname] = 'Inconsolata'
    node_hash = Hash.new

    (expl_dependencies.keys + non_expl_dependencies.keys).uniq.each { |node_name|
      subgraphs = Array.new
      name_unification[node_name].each { |node|
        subgraphs += node.parallel_loops
      }
      subgraphs.uniq!
      sub_g = g
      subgraphs.each { |subgraph|
        sub_g = sub_g.add_graph("cluster#{subgraph.__id__}".inspect)
        sub_g[:label] = subgraph.name
        sub_g[:color] = 'black'
      }
      new_node = sub_g.add_nodes(node_name.inspect)
      node_hash[node_name]  = new_node
      new_node[:label] = node_name
      new_node[:style] = 'bold'
      if name_unification[node_name].first.sons.first.name.start_with? "get_result" or # a.get_result
         (not name_unification[node_name].first.sons.first.sons.empty? and
          name_unification[node_name].first.sons.first.sons.first.name.start_with? "get_result") # for a.get_result.foo()
        new_node[:shape] = 'square'
      elsif name_unification[node_name].first.sons.first.name.start_with? "async"
        new_node[:shape] = 'circle'
      elsif name_unification[node_name].first.grid_obj?
        new_node[:shape] = 'hexagon'
      else
        new_node[:color] = 'red'
        new_node[:shape] = 'ellipse'
      end
    }

    {"expl" => expl_dependencies, "non_expl" => non_expl_dependencies}.each { |dep_kind, dep_dict|
      dep_dict.each { |key, value|
        value.each { |k|
          if name_unification[k].first.grid_obj?
            if dep_kind == "expl"
              new_edge = g.add_edges(node_hash[k], node_hash[key])
              new_edge[:style] = 'solid'
              new_edge[:dir] = 'none'
              new_edge[:weight] = '1'
            end
          else
            new_edge = g.add_edges(node_hash[k], node_hash[key])
            new_edge[:arrowhead] = 'normal'

            if name_unification[key].first.sons.first.name.start_with? "get_result" or # a.get_result
                (not name_unification[key].first.sons.first.sons.empty? and
                 name_unification[key].first.sons.first.sons.first.name.start_with? "get_result") # for a.get_result.foo()

              if dep_kind == "expl"
                new_edge[:style] = 'solid'
                new_edge[:weight] = '100'
              elsif dep_kind == "non_expl"
                new_edge[:style] = 'dotted'
                new_edge[:weight] = '1'
              end
              new_edge[:arrowhead] = 'empty'
            elsif name_unification[key].first.sons.first.name.start_with? "async"

              if dep_kind == "expl"
                new_edge[:style] = 'bold'
                new_edge[:weight] = '100'
              elsif dep_kind == "non_expl"
                new_edge[:style] = 'dashed'
                new_edge[:weight] = '1'
              end
            else
              new_edge[:color] = 'red'
            end
          end
        }
      }
    }

    g.output :none => String
  end

  def DAG.make_dependencies_dotgraph(dag_tree)
    g = GraphViz::new("alldependencies")
    g.node[:fontname] = 'Inconsolata'
    g.edge[:fontname] = 'Inconsolata'
    t = Time.new
    # g[:label] = t.getlocal.to_s
    nodes_hash = Hash.new
    dag_tree.nodes.each do |node|
      g_node = g.add_nodes(node.hash.inspect)
      g_node[:label] = node.get_name
      nodes_hash[node] = g_node
      g_node[:shape] = 'triangle' if node.type == :if
      g_node[:shape] = 'circle' if node.type == :loop
      g_node[:shape] = 'doublecircle' if node.type == :p_loop
    end
    dag_tree.edges.each do |dag_edge|
      g_edge = g.add_edges(nodes_hash[dag_edge.from], nodes_hash[dag_edge.to])
      g_edge[:label] = dag_edge.deps.join(', ')
      g_edge[:style] = 'dotted' if dag_edge.type == :exit
      g_edge[:style] = 'dashed' if dag_edge.type == :if_or_loop
    end
    g.output :none => String
  end
end
