module Dry
  module Mutations
    module Transactions # :nodoc:
      # http://dry-rb.org/gems/dry-transaction/custom-step-adapters/
      # step adapters must provide a single `#call(step, *args, input)` method,
      #   which should return the step’s result wrapped in an `Either` object.
      # This one is a wrapper for neted chains
      class Chain < StepAdapters::Move
        # def call(step, *args, input)
        #   if step.block
        #     Class.new do
        #       extend ::Dry::Mutations::Transactions::DSL
        #       chain(&step.block)
        #     end.(input, *args)
        #   else
        #     super
        #   end
        # end
      end
    end
  end
end
