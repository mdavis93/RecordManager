class SelectionDynamicFinder
  attr_accessor :attribute

  def initialize(method_sym)
    @attribute = $1.to_sym if method_sym.to_s =~ /^find_by_(.*)$/
  end

  def match?
    @attribute != nil
  end
end