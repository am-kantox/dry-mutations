module Dry
  module Mutations
    module Transactions # :nodoc:
      # http://dry-rb.org/gems/dry-transaction/basic-usage/
      # save_user = Dry.Transaction(container: Container) do
      #   step :process
      #   step :validate
      #   step :persist
      # end

      module DSL # :nodoc:
        include Dry::Monads::Either::Mixin

        # rubocop:disable Style/MultilineIfModifier
        def self.extended base
          fail Errors::TypeError.new("Extended class [#{base}] should not respond to :call, it is defined by this extension.") if base.respond_to?(:call)
          base.send :define_method, :initialize do |*input|
            @input = Utils.RawInputs(*input)
          end unless base.instance_methods(false).include?(:initialize)
          %i(call run run!).each do |meth|
            base.send :define_method, meth do
              base.public_send(meth, @input)
            end unless base.instance_methods(false).include?(meth)
          end
        end
        # rubocop:enable Style/MultilineIfModifier

        def chain **params, &λ
          return enum_for(:chain) unless block_given? # FIXME: Needed? Works? Remove?

          # rubocop:disable Style/VariableNumber
          λ = Proc.new

          @transaction = Class.new do
            include ::Dry::Transaction(
              container: ::Dry::Mutations::Transactions::Container,
              step_adapters: StepAdapters
            )
            # class_eval(&λ) if λ
            module_eval(&λ) if λ
          end.new.tap do |transaction|
            singleton_class.send :define_method, :call do |*input|
              transaction.(Utils.RawInputs(*input))
            end
            singleton_class.send :define_method, :run do |*input|
              ::Dry::Mutations::Extensions::Outcome(transaction.(Utils.RawInputs(*input)))
            end
            singleton_class.send :define_method, :run! do |*input|
              ::Dry::Mutations::Extensions::Outcome!(transaction.(Utils.RawInputs(*input)))
            end
          end
          # rubocop:enable Style/VariableNumber
        end
      end
    end
  end
end
