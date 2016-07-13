module Dry
  module Mutations
    module Extensions
      module Command # :nodoc:
        def self.prepended base
          fail ArgumentError, "Can not prepend #{self.class} to #{base.class}: base class must be a ::Mutations::Command descendant." unless base < ::Mutations::Command
          base.extend(DSL::Module) unless base.ancestors.include?(DSL::Module)
          base.extend(Module.new do
            def call(*args)
              new(*args).call
            end

            def to_proc
              ->(*args) { new(*args).call }
            end

            if base.name && !::Kernel.methods.include?(base_name = base.name.split('::').last.to_sym)
              ::Kernel.class_eval <<-FACTORY, __FILE__, __LINE__ + 1
                def #{base_name}(*args)
                  puts "Gonna call [#{base}.call(*args)] with \#{args.inspect}"
                  #{base}.call(*args)
                end
              FACTORY
            end
          end)
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

        ########################################################################
        ### Functional helpers
        ########################################################################

        def call
          run.either
        end

        ########################################################################
        ### Overrides
        ########################################################################

        def validation_outcome(result = nil)
          # Outcome.new(!has_errors?, has_errors? ? nil : result, @errors, @inputs)
          super.tap do |outcome|
            outcome.singleton_class.tap do |klazz|
              klazz.prepend Outcome unless klazz.ancestors.include?(Outcome)
            end
            outcome.eitherify!
          end
        end

        def execute
          super
        rescue => e
          add_error(:♻, :runtime_exception, e.message)
        end

        def add_error(key, kind, message = nil, dry_message = nil)
          fail ArgumentError.new("Invalid kind #{kind}") unless kind.is_a?(Symbol)

          path = key.to_s.split('.')
          # ["#<struct Dry::Validation::Message
          #            predicate=:int?,
          #            path=[:maturity_set, :maturity_days_set, :days],
          #            text=\"must be an integer\",
          #            options={:args=>[], :rule=>:days, :each=>false}>"
          dry_message ||= ::Dry::Validation::Message.new(kind, *path.map(&:to_sym), message, rule: :♻)
          atom = Errors::ErrorAtom.new(key, kind, dry_message, message: message)

          last = path.pop
          (@errors ||= ::Mutations::ErrorHash.new).tap do |errs|
            path.inject(errs) do |cur_errors, part|
              cur_errors[part.to_sym] ||= ::Mutations::ErrorHash.new
            end[last] = atom
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
