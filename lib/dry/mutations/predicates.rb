module Dry
  module Mutations
    module Predicates # :nodoc:
      include ::Dry::Logic::Predicates

      predicate(:duck?) do |expected, current|
        expected.empty? || expected.all?(&current.method(:respond_to?))
      end

      predicate(:default?) do |_expected, _current|
        true
        # fail Errors::TypeError, "“default” guard is not implemented yet in dry-mutations, sorry for that."
      end

      # FIXME: at the moment this is an exact equivalent of :type? => User
      predicate(:model?) do |expected, current|
        return true if expected.nil?
        expected = begin
                     ::Kernel.const_get(expected)
                   rescue TypeError => e
                     raise Errors::TypeError, "Bad “model” type. Error: [#{e.message}]"
                   rescue NameError => e
                     raise Errors::TypeError, "Bad “model” class. Error: [#{e.message}]"
                   end unless expected.is_a? Module
        current.is_a?(expected)
      end

      predicate(:discard_empty) do |_expected, _current|
        true
      end

      predicate(:class) do |_expected, _current|
        true
      end
    end
  end
end
