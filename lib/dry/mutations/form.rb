module Dry
  module Mutations
    class Form < ::Dry::Validation::Form
      @@discarded = []

      configure(&::Dry::Validation::Schema::CONFIGURATOR)
      # predicates(::Dry::Mutations::Predicates)

      def discarded
        @@discarded
      end

      def discarded?
        discarded.empty?
      end

      def discarded! value
        discarded << value
      end
    end
  end
end
