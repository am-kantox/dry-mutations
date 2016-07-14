module Dry
  module Mutations
    module Transactions # :nodoc:
      Container = lambda do |whatever|
        whatever.respond_to?(:call) ? whatever : Utils.Constant(whatever).tap do |p|
          fail ArgumentError, "The argument must respond to :call, though #{k.inspect} passed." unless p.respond_to? :call
        end
      end
    end
  end
end
