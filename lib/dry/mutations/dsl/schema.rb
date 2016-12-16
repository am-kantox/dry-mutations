module Dry
  module Mutations
    module DSL # :nodoc:
      module Schema # :nodoc:
        def schema *args, input_processor: nil, **options, &block
          case args.count
          when 0, 1
            schema, = args
            @schema ||= patched_schema(schema) || derived_schema(input_processor: input_processor, **options, &block)
            return @schema unless block_given?

            @schema = Validation.Schema(@schema, **@schema.options, &Proc.new)
          when 2 # explicit dry schema given
            name = args.first
            current = @current # closure scope

            schema do
              Utils.smart_send(__send__(current, name), :schema, args.last, **options, &block)
            end
            define_method(name) { Utils::Hash(@inputs[name]) }
          end
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

        def patched_schema(schema)
          return nil unless schema.is_a?(::Dry::Validation::Schema)
          schema.tap do |s|
            s.config.instance_eval(&::Dry::Mutations::Schema::CONFIGURATOR)
          end
        end
      end
    end
  end
end
