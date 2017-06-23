# Well, I expect tons of questions about this.
# Just let it stay, unless I understand the cause of exception thrown
#   in this particular case.

# rubocop:disable Style/ClassAndModuleChildren
class Dry::Logic::Rule::Value < Dry::Logic::Rule
  def input
    predicate.args.last rescue nil
  end
end

module Dry
  module Transaction
    class OperationResolver < Module # :nodoc:
      def initialize(container)
        module_exec(container) do
          define_method :initialize do |**kwargs|
            super(**kwargs)
          end
        end
      end
    end
  end
end

module Dry
  module Transaction
    class Step # :nodoc:
      def initialize(step_adapter, step_name, operation_name, operation, options, call_args = [])
        @step_adapter = step_adapter
        @step_name = step_name
        @operation_name = operation_name
        @operation = operation
        @operation ||= @operation_name if @operation_name.respond_to?(:call)
        @options = options
        @call_args = call_args
      end
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
