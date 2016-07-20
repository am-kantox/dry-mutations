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

        def self.extended base
          fail Errors::TypeError.new("Extended class [#{base}] should not respond to :call, it is defined by this extension.") if base.respond_to?(:call)
        end

        def chain **params
          return enum_for(:chain) unless block_given? # FIXME: Needed? Works? Remove?

          λ = Proc.new

          @transaction = ::Dry.Transaction(container: ::Dry::Mutations::Transactions::Container, step_adapters: StepAdapters) do
            instance_eval(&λ)
          end.tap do |transaction|
            singleton_class.send :define_method, :call do |input|
              transaction.(input)
            end
            singleton_class.send :define_method, :run do |input|
              ::Dry::Mutations::Extensions::Outcome(transaction.(input))
            end
          end
        end
      end
    end
  end
end
