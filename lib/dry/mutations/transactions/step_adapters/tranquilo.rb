module Dry
  module Mutations
    module Transactions # :nodoc:
      # http://dry-rb.org/gems/dry-transaction/custom-step-adapters/
      # step adapters must provide a single `#call(step, *args, input)` method,
      #   which should return the step’s result wrapped in an `Either` object.
      class Tranquilo < StepAdapters::Move # :nodoc:
        def call(step, *args, input)
          # TODO: FIXME: PENDING: when block passing is merged into dry-validation
          step.operation.(input, *args)
        end
      end
    end
  end
end
