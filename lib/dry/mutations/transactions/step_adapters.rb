module Dry
  module Mutations
    module Transactions # :nodoc:
      # http://dry-rb.org/gems/dry-transaction/custom-step-adapters/
      # step adapters must provide a single `#call(step, *args, input)` method,
      #   which should return the step’s result wrapped in an `Either` object.
      class StepAdapters < ::Dry::Transaction::StepAdapters # :nodoc:
        class Move # :nodoc:
          def self.inherited(sub)
            name = Utils.Snake(sub, short: true, symbolize: true)
            StepAdapters.register name, sub.new
            adapters[name] = sub

            sub.prepend(Module.new do
              def call(step, *args, input)
                outcome = super
              ensure
                ::Dry::Mutations::Utils.extend_outcome outcome.value, "#{step.step_name}::#{step.operation_name}" if outcome
              end
            end)
          end

          def self.adapters
            @adapters ||= Utils.Hash
          end

          def call(step, *args, input)
            step.operation.(input, *args, &step.block)
          end
        end

        # preload predefined step adapters
        Dir[File.expand_path('step_adapters', __dir__) << '/*'].each do |f|
          require_relative f
        end
      end
    end
  end
end
