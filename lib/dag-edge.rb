class DagEdge
  attr_accessor :from, :to, :deps, :type

  def initialize(from, to, deps, type = :normal)
    @from = from
    @to = to
    @deps = deps
    @type = type
  end
end
