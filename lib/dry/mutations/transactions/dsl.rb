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
        def chain **params
          return enum_for(:chain) unless block_given? # FIXME: Needed? Works? Remove?

          λ = Proc.new

          ::Dry.Transaction(container: ::Dry::Mutations::Transactions::Container, step_adapters: StepAdapters) do
            instance_eval(&λ)
          end
        end
      end
    end
  end
end
