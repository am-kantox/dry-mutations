module Dry
  module Mutations
    class Schema < ::Dry::Validation::Schema
      MESSAGES_FILE = (::File.join __dir__, '..', '..', '..', 'config', 'messages.yml').freeze

      configure do |config|
        config.messages_file = MESSAGES_FILE
        config.hash_type = :symbolized
        config.input_processor = :sanitizer

        predicates(::Dry::Mutations::Predicates)
      end
    end
  end
end
