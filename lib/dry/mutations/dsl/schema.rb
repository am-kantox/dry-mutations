module Dry
  module Mutations
    module DSL # :nodoc:
      module Schema # :nodoc:
        def schema schema = nil, input_processor: nil, **options, &block
          @schema ||= schema || derived_schema(input_processor: input_processor, **options, &block)
          return @schema unless block_given?

          @schema = Validation.Schema(@schema, **@schema.options, &Proc.new)
        end

        private

        def derived_schema input_processor: nil, **options, &block
          this = is_a?(Class) ? self : self.class

          parent_with_schema = this.ancestors.drop(1).detect do |klazz|
            next if [this, ::Mutations::Command, ::Dry::Mutations::Extensions::Command].include?(klazz)
            klazz.respond_to?(:schema) && klazz.schema.is_a?(Validation::Schema)
          end

          if parent_with_schema
            Class.new(parent_with_schema.schema.class).new
          else
            ::Dry::Mutations.Schema(input_processor: input_processor, **options, &block)
          end
        end
      end
    end
  end
end
