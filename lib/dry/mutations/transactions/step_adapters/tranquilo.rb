module Dry
  module Mutations
    module Transactions # :nodoc:
      # http://dry-rb.org/gems/dry-transaction/custom-step-adapters/
      # step adapters must provide a single `#call(step, *args, input)` method,
      #   which should return the step’s result wrapped in an `Either` object.
      class Tranquilo < StepAdapters::Move # :nodoc:
      end
    end
  end
end
