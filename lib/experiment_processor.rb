require 'rubygems'
require 'ruby_parser'
require 'ruby_lexer'
require 'sexp_processor'
require 'experiment_node'

class ExperimentProcessor < SexpProcessor
  attr_accessor :tree
  def initialize
    super
    self.auto_shift_type = true
    @tree = Node.new
    @actual_node = tree
    # @require_empty = false
  end

  def change_to_new
    new_node = Node.new
    new_node.parent = @actual_node
    @actual_node.sons << new_node
    @actual_node = new_node
  end

  def change_to_parrent
    @actual_node = @actual_node.parent
  end

  def exec_process(exp)
    change_to_new
    result = process(exp)
    change_to_parrent
    result
  end

  def process_block(exp)
    @actual_node.node_type = :block
    block_content = Array.new
    while not exp.empty? do
      block_content << exec_process(exp.shift)
    end
    Sexp.from_array([:block] + block_content)
  end

  def process_lvar(exp)
    var = exp.shift
    @actual_node.name = var.to_s
    @actual_node.node_type = :lval
    s(:lvar, var)
  end

  def process_args(exp)
    # doesn't handle arguments with default value and other exotic constructs
    arg_names = Array.new
    while not exp.empty? do
      arg_names << exp.shift
    end
    @actual_node.node_type = :args
    @actual_node.name = arg_names.join(" ")
    Sexp.from_array([:args] + arg_names)
  end

  def process_class(exp)
    name = exp.shift

    inherit = exec_process(exp.shift)

    @actual_node.node_type = :class
    @actual_node.name = name.to_s + " dziedziczy z: " + inherit.to_s

    s(:class, name, inherit, exec_process(exp.shift))
  end

  def process_defn(exp)
    name = exp.shift

    @actual_node.node_type = :defn
    @actual_node.name = name.to_s

    # (:defn, name, args, scope)
    s(:defn, name, exec_process(exp.shift), exec_process(exp.shift), exec_process(exp.shift))
  end

  def process_scope(exp)
    @actual_node.node_type = :scope
    s(:scope, exec_process(exp.shift))
  end

  def process_call(exp)
    if exp.length >= 3
      first_argument = exec_process(exp.shift)

      method_name = exp.shift
      @actual_node.node_type = :call
      @actual_node.name = method_name.to_s

      elements = Array.new
      while not exp.empty? do
        elements << exec_process(exp.shift)
      end

      s(:call, first_argument, method_name, Sexp.from_array(elements))
    else
      method_name = exp.pop
      @actual_node.node_type = :call
      @actual_node.name = method_name.to_s
      s(:call, exec_process(exp.shift), method_name)
    end
  end

  def process_arglist(exp)
    @actual_node.node_type = :arglist
    elements = Array.new

    while not exp.empty? do
      elements << exec_process(exp.shift)
    end
    Sexp.from_array([:arglist] + elements)
  end

  def process_return(exp)
    @actual_node.node_type = :return
    s(:return, exec_process(exp.shift))
  end

  # what is 'rest' in loops
  # rest is TRUE when:
  # => until(condition)
  # =>   do_sth
  # => end
  # => while(condition)
  # =>   do_sth
  # => end
  # rest is FALSE when:
  # => begin
  # =>   do_sth
  # => end while condition

  def process_while(exp)
    @actual_node.node_type = :while
    @actual_node.name = "loop"
    condition = exec_process(exp.shift)
    body = exec_process(exp.shift)
    rest = exp.shift
    #puts "while rest: #{rest}" # pamietaj o rest
    s(:while, condition, body, rest)
  end

  def process_until(exp)
    @actual_node.node_type = :until
    @actual_node.name = "loop"
    condition = exec_process(exp.shift)
    body = exec_process(exp.shift)
    rest = exp.shift
    #puts "until rest: #{rest}" # pamietaj o rest
    s(:while, condition, body, rest)
  end

  def process_const(exp)
    name = exp.shift
    @actual_node.name = name.to_s
    @actual_node.node_type = :const
    s(:const, name)
  end

  def process_fcall(exp)
    name = exp.shift
    @actual_node.name = name.to_s
    @actual_node.node_type = :fcall
    s(:fcall, name, exec_process(exp.shift))
  end

  def process_vcall(exp)
    name = exp.shift
    @actual_node.name = name.to_s
    @actual_node.node_type = :vcall
    s(:vcall, name)
  end

  def process_array(exp)
    @actual_node.node_type = :array

    elements = Array.new

    while not exp.empty? do
      elements << exec_process(exp.shift)
    end
    Sexp.from_array([:array] + elements)
  end

  def process_str(exp)
    value = exp.shift
    @actual_node.name = value.to_s
    @actual_node.node_type = :str
    s(:str, value)
  end

  def process_lasgn(exp)
    var_name = exp.shift
    @actual_node.name = var_name.to_s
    @actual_node.node_type = :lasgn
    if exp.length > 0
      s(:lasgn, var_name, exec_process(exp.shift))
    else
      s(:lasgn, var_name)
    end
  end

  def process_lit(exp)
    value = exp.shift
    @actual_node.name = value.to_s
    @actual_node.node_type = :lit
    s(:lit, value)
  end

  def process_iter(exp)
    @actual_node.name = "loop"
    @actual_node.node_type = :iter
    s(:iter, exec_process(exp.shift), exec_process(exp.shift), exec_process(exp.shift))
  end

  def process_dasgn_curr(exp)
    name = exp.shift
    @actual_node.name = name.to_s
    @actual_node.node_type = :dasgn_curr
    s(:dasgn_curr, name)
  end

  def process_dstr(exp)
    #smth like puts "string #{x}"
    first_str = exp.shift
    @actual_node.name = first_str.to_s
    @actual_node.node_type = :dstr

    string_content = Array.new
    string_content << first_str
    while not exp.empty? do
      string_content << exec_process(exp.shift)
    end
    Sexp.from_array([:dstr] + string_content)
  end

  def process_evstr(exp)
    # for process_dstr
    @actual_node.node_type = :evstr
    s(:evstr, exec_process(exp.shift))
  end

  def process_if(exp)
    @actual_node.node_type = :if
    s(:if, exec_process(exp.shift), exec_process(exp.shift), exec_process(exp.shift))
  end

  def process_yield(exp)
    @actual_node.node_type = :yield
    s(:yield, exec_process(exp.shift))
  end

  def process_block_arg(exp)
    @actual_node.node_type = :block_arg
    block_arg = exp.shift
    @actual_node.name = block_arg.to_s
    s(:block_arg, block_arg)
  end

  def process_masgn(exp)
    @actual_node.node_type = :masgn

    masgn_content = Array.new
    while not exp.empty? do
      masgn_content << exec_process(exp.shift)
    end
    Sexp.from_array([:masgn] + masgn_content)
  end

  def process_iasgn(exp)
    @actual_node.node_type = :iasgn
    name = exp.shift
    @actual_node.name = name.to_s
    s(:iasgn, name, exec_process(exp.shift))
  end

  def process_ivar(exp)
    @actual_node.node_type = :ivar
    content = exp.shift
    @actual_node.name = content.to_s
    s(:ivar, content)
  end

  def process_dvar(exp)
    @actual_node.node_type = :dvar
    content = exp.shift
    @actual_node.name = content.to_s
    s(:dvar, content)
  end

  def process_attrasgn(exp)
    @actual_node.node_type = :attrasgn
    argument = exec_process(exp.shift)
    operation = exp.shift
    parameter = exec_process(exp.shift)
    @actual_node.name = operation.to_s
    s(:attrasgn, argument, operation, parameter, exec_process(exp.shift))
  end

  def process_zarray(exp)
    @actual_node.node_type = :zarray
    s(:zarray)
  end

  def process_hash(exp)
    # does not distinguish what is a key and what is a value
    @actual_node.node_type = :hash
    elements = Array.new
    while not exp.empty? do
      elements << exec_process(exp.shift)
    end
    Sexp.from_array([:hash] + elements)
  end

  def process_self(exp)
    @actual_node.node_type = :self
    s(:self)
  end

  def process_for(exp)
    @actual_node.node_type = :for

    content = Array.new
    while not exp.empty? do
      content << exec_process(exp.shift)
    end
    Sexp.from_array([:for] + content)
  end

  def process_dot3(exp)
    @actual_node.node_type = :dot3

    content = Array.new
    while not exp.empty? do
      content << exec_process(exp.shift)
    end
    Sexp.from_array([:dot3] + content)
  end

  def process_nil(exp)
    @actual_node.node_type = :nil
    s(:nil)
  end

  def process_true(exp)
    @actual_node.node_type = :true
    s(:true)
  end

  def process_false(exp)
    @actual_node.node_type = :false
    s(:false)
  end

  def analyze_file(file)
    tree = RubyParser.new.parse(file)
#    puts "#{tree}"
    process(tree)
  end
end
