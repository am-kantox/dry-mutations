module Dry
  module Mutations
    class Form < ::Dry::Validation::Form # :nodoc:
      @discarded = []

      configure(&::Dry::Validation::Schema::CONFIGURATOR)
      # predicates(::Dry::Mutations::Predicates)

      def discarded
        self.class.instance_variable_get :@discarded
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
