module Dry
  module Mutations
    class Schema < ::Dry::Validation::Schema
      @@discarded = []

      MESSAGES_FILE = (::File.join __dir__, '..', '..', '..', 'config', 'messages.yml').freeze
      CONFIGURATOR = ->(config) do
        config.messages_file = MESSAGES_FILE
        config.hash_type = :symbolized
        config.input_processor = :sanitizer if config.input_processor == :noop
        config.predicates = ::Dry::Mutations::Predicates
        this = is_a?(::Dry::Validation::Schema) ? self : singleton_class
        config.registry = ::Dry::Validation::PredicateRegistry[this, config.predicates]
      end

      configure(&CONFIGURATOR)
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
