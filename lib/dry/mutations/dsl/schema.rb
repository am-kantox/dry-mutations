module Dry
  module Mutations
    module DSL # :nodoc:
      MESSAGES_FILE = (::File.join __dir__, '..', '..', '..', '..', 'config', 'messages.yml').freeze

      def self.Schema
        Validation.Schema do
          configure do
            # config.messages = :i18n
            config.messages_file = MESSAGES_FILE
            config.hash_type = :symbolized
            config.input_processor = :sanitizer

            predicates(Mutations::Predicates)
          end
        end
      end

      module Schema # :nodoc:
        def schema
          @schema ||= derived_schema
          return @schema unless block_given?

          @schema = Validation.Schema(@schema, **@schema.options, &Proc.new)
        end

        private

        def derived_schema
          this = is_a?(Class) ? self : self.class

          parent_with_schema = this.ancestors.drop(1).detect do |klazz|
            next if [this, ::Mutations::Command, ::Dry::Mutations::Extensions::Command].include?(klazz)
            klazz.respond_to?(:schema) && klazz.schema.is_a?(Validation::Schema)
          end
          parent_with_schema ? Class.new(parent_with_schema.schema.class).new : ::Dry::Mutations::DSL::Schema()
        end
      end
    end
  end
end
