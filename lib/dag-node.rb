class DagNode
  attr_accessor :name, :program_nodes, :type, :if_statements, :loop_statements,
  :condition

  def initialize(node_name, type = :job)
    @name = node_name
    @type = type
    @if_statements = Array.new
    @loop_statements = Array.new
  end

  def get_method
    @program_nodes.each do |node|
      return "#{node.sons.first.name}(#{node.sons.first.get_arg_list})" if node.sons.first.node_type == :call
    end
    return ''
  end

  def get_variable
    @program_nodes.each do |node|
      if node.sons.first.node_type == :call
        node.sons.first.sons.each do |sons_node|
          return "#{sons_node.name}" if sons_node.node_type == :lval
        end
      end
    end
    return ''
  end

  def get_name
    if @type == :if then
      "if(#{get_condition})"
    elsif @type == :loop
      "loop"
    elsif @type == :p_loop
      "parallelFor"
    else
      "#{@name} = #{get_variable}.#{get_method}"
    end
  end

  def get_condition
    condition = @program_nodes.first.sons.first
    if condition.node_type == :call
      "#{condition.sons.first.name} #{condition.name}"
    else
      "#{condition.name}"
    end
  end
end
