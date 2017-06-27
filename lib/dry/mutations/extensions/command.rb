module Dry
  module Mutations
    module Extensions
      module Command # :nodoc:
        include Dry::Monads::Either::Mixin

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
                  #{base}.call(*args)
                end
              FACTORY
            end
          end)

          base.singleton_class.prepend(Module.new do
            def respond_to_missing?(method_name, include_private = false)
              %i|call to_proc|.include?(method_name) || super
            end
          end)
        end

        attr_reader :validation

        def initialize(*args)
          @raw_inputs = defaults.merge(Utils.RawInputs(*args))
          @validation_result = discard_empty!
          @inputs = Utils.Hash @validation_result.output

          fix_accessors!

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
        ### Legacy mutations support
        ########################################################################

        def vacant?(value)
          case value
          when NilClass then true
          when Integer, Float then false # FIXME: make sure!
          when ->(v) { v.respond_to? :empty? } then value.empty?
          when ->(v) { v.respond_to? :blank? } then value.blank?
          else false
          end
        end

        def discard_empty!
          discarded = schema.respond_to?(:discarded) ? schema.discarded : []
          schema.(
            ::Dry::Mutations::Utils.Hash(@raw_inputs.reject { |k, v| discarded.include?(k.to_sym) && vacant?(v) })
          )
        end

        ########################################################################
        ### Overrides
        ########################################################################

        def validation_outcome(result = nil)
          ::Dry::Mutations::Extensions::Outcome(super)
        end

        def execute
          super
        rescue => e
          add_error(:♻, :runtime_exception, e.message)
          raise e
        end

        def add_error(key, kind, message = nil, dry_message = nil)
          fail ArgumentError.new("Invalid kind #{kind}") unless kind.is_a?(Symbol)

          path = key.to_s.split('.')
          # ["#<struct Dry::Validation::Message
          #            predicate=:int?,
          #            path=[:maturity_set, :maturity_days_set, :days],
          #            text=\"must be an integer\",
          #            options={:args=>[], :rule=>:days, :each=>false}>"
          last = path.pop
          dry_message ||= ::Dry::Validation::Message.new(kind, last, message, rule: :♻)
          atom = Errors::ErrorAtom.new(last, kind, dry_message, message: message)

          (@errors ||= ::Mutations::ErrorHash.new).tap do |errs|
            path.inject(errs) do |cur_errors, part|
              cur_errors[part.to_s] ||= ::Mutations::ErrorHash.new
            end[last] = atom
          end # [key] = Errors::ErrorAtom.new(key, kind, dry_message, message: message)
        end

        def messages
          @messages ||= yield_messages.uniq
        end

        private

        def yield_messages(flat = [], errors = @errors)
          return flat unless errors
          errors = errors.values if errors.is_a?(Hash)
          errors.each_with_object(flat) do |error, acc|
            case error
            when ::Mutations::ErrorHash, ::Mutations::ErrorArray then yield_messages(acc, error)
            when ::Dry::Mutations::Errors::ErrorAtom then acc << error.dry_message
            when ::Mutations::ErrorAtom then acc << error.message
            end
          end
        end

        def schema
          @schema ||= self.class.schema
        end

        def predicates(input, digged = [])
          case input
          when Dry::Logic::Rule::Predicate then digged << input
          when Array, ActiveRecord::Relation then input.each { |e| predicates(e, digged) }
          when ->(i) { i.respond_to?(:rules) } then predicates(input.rules, digged)
          end
          digged
        end

        # rubocop:disable Style/YodaCondition
        def dig(predicate, input = schema)
          case input.rules
          when Hash # the whole schema
            input.rules.map do |k, v|
              pred = predicates(v).detect do |p|
                p.respond_to?(:predicate) &&
                  (p = p.predicate).is_a?(Method) &&
                  "#{p.owner}##{p.name}" == predicate
              end
              pred ? [k, pred] : nil
            end.compact.to_h
          else
            predicates(input).detect do |p|
              "#{p.owner}##{p.name}" == predicate
            end
          end
        end
        # rubocop:enable Style/YodaCondition

        def defaults
          ::Dry::Mutations::Utils.Hash(
            dig('#<Class:Dry::Mutations::Predicates>#default?').map do |k, v|
              next unless v.respond_to?(:options) && v.options[:args]
              [k, v.options[:args].first]
            end.compact.to_h
          )
        end

        def fix_accessors!
          schema.rules.keys.each do |method|
            next if respond_to?(name = method)

            singleton_class.tap do |c|
              c.send(:define_method, name) { @inputs[name] }
              if c < Enumerable
                c.send(:define_method, :"#{name}_present?") do
                  @inputs.key?(name) && !@inputs[name].empty?
                end
              else
                c.send(:define_method, :"#{name}_present?") { @inputs.key?(name) }
                c.send(:define_method, :"#{name}=") { |value| @inputs[name] = value }
              end
            end
          end
        end
      end
    end
  end
end
