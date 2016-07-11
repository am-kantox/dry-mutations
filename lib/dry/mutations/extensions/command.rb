module Dry
  module Mutations
    module Extensions
      module Command # :nodoc:
        def self.prepended base
          fail ArgumentError, "Can not prepend #{self.class} to #{base.class}: base class must be a ::Mutations::Command descendant." unless base < ::Mutations::Command
          base.extend(DSL::Module) unless base.ancestors.include?(DSL::Module)
        end

        attr_reader :validation

        def initialize(*args)
          @raw_inputs = args.inject(Utils.Hash({})) do |h, arg|
            fail ArgumentError.new('All arguments must be hashes') unless arg.is_a?(Hash)
            h.merge!(arg)
          end

          @validation_result = schema.(@raw_inputs)

          @inputs = Utils.Hash @validation_result.output

          # dry: {:name=>["size cannot be greater than 10"],
          #       :properties=>{:first_arg=>["must be a string", "is in invalid format"]},
          #       :second_arg=>{:second_sub_arg=>["must be one of: 42"]},
          #       :amount=>["must be one of: 42"]}}
          # mut: {:name=>#<Mutations::ErrorAtom:0x00000009534e50 @key=:name, @symbol=:max_length, @message=nil, @index=nil>,
          #       :properties=>{
          #           :second_arg=>{:second_sub_arg=>#<Mutations::ErrorAtom:0x000000095344a0 @key=:second_sub_arg, @symbol=:in, @message=nil, @index=nil>}
          #       :amount=>#<Mutations::ErrorAtom:0x00000009534068 @key=:amount, @symbol=:in, @message=nil, @index=nil>}

          @errors = Errors::ErrorAtom.patch_message_set(
            Errors::ErrorCompiler.new(schema).(@validation_result.to_ast.last)
          )

          # Run a custom validation method if supplied:
          validate unless has_errors?
        end

        def validation_outcome(result = nil)
          # Outcome.new(!has_errors?, has_errors? ? nil : result, @errors, @inputs)
          super.tap do |outcome|
            outcome.singleton_class.tap do |klazz|
              klazz.prepend Outcome unless klazz.ancestors.include?(Outcome)
            end
            outcome.eitherify!
          end
        end

        def messages
          @messages ||= @errors && @errors.values.map(&:dry_message)
        end

        private

        def schema
          @schema ||= self.class.schema
        end
      end
    end
  end
end
