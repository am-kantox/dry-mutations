module Dry
  module Mutations
    module DSL
      module Schema # :nodoc:
        def schema
          @schema ||= derived_schema
          return @schema unless block_given?

          @schema = Validation.Schema(@schema, **@schema.options, &Proc.new)
        end

        private

        def derived_schema
          this = is_a?(Class) ? self : self.class
          parent_with_schema = this.ancestors.tap(&:shift).detect do |klazz|
            break if klazz == Mutations::Command
            klazz.respond_to?(:schema) && klazz.schema.is_a?(Validation::Schema)
          end
          parent_with_schema ? Class.new(parent_with_schema.schema.class).new : empty_schema
        end

        def empty_schema
          Validation.Schema do
            configure do
              # config.messages = :i18n
              config.messages_file = ::File.join __dir__, '..', '..', '..', '..', 'config', 'messages.yml'
              config.hash_type = :symbolized
              config.input_processor = :sanitizer

              predicates(Mutations::Predicates)
            end
          end
        end
      end
    end
  end
end
