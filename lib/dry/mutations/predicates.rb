module Dry
  module Mutations
    module Predicates # :nodoc:
      include ::Dry::Logic::Predicates

      predicate(:duck?) do |expected, current|
        expected.empty? || expected.all?(&current.method(:respond_to?))
      end

      # FIXME: at the moment this is an exact equivalent of :type? => User
      predicate(:model?) do |expected, current|
        expected.nil? || current.is_a?(expected)
      end
    end
  end
end
