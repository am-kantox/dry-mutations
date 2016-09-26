Dry::Types::Sum::Constrained.prepend(Module.new do
  def primitive
    case
    when [left, right].map(&:type).map(&:primitive) == [TrueClass, FalseClass] then ::Dry::Types['bool']
    end
  end
end)
