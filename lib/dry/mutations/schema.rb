module Dry
  module Mutations
    class Schema < ::Dry::Validation::Schema
      @@discarded = []

      MESSAGES_FILE = (::File.join __dir__, '..', '..', '..', 'config', 'messages.yml').freeze

      configure do |config|
        config.messages_file = MESSAGES_FILE
        config.hash_type = :symbolized
        config.input_processor = :sanitizer

        config.instance_variable_set :@discarded, []

        predicates(::Dry::Mutations::Predicates)
      end

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
