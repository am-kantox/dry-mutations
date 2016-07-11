require 'dry-matcher'
require 'dry-monads'

module Dry
  module Mutations
    module Extensions
      module Outcome # :nodoc:
        include Dry::Monads::Either::Mixin

        class EitherCalculator # :nodoc:
          include Dry::Monads::Either::Mixin

          attr_accessor :outcome

          def calculate
            Right(outcome).bind do |value|
              if value.success?
                Right(value.result)
              else
                Left(value.errors)
              end
            end
          end
        end

        # class Matcher # :nodoc:
        #   # Match `[:ok, some_value]` for success
        #   SUCCESS = Dry::Matcher::Case.new(
        #     match: -> value { value.first == :ok },
        #     resolve: -> value { value.last }
        #   )
        #
        #   # Match `[:err, some_error_code, some_value]` for failure
        #   failure_case = Dry::Matcher::Case.new(
        #     match: -> value, *pattern {
        #       value[0] == :err && (pattern.any? ? pattern.include?(value[1]) : true)
        #     },
        #     resolve: -> value { value.last }
        #   )
        #
        #   # Build the matcher
        #   matcher = Dry::Matcher.new(success: success_case, failure: failure_case)
        # end

        def self.prepended base
          fail ArgumentError, "Can not prepend #{self.class} to #{base.class}: base class must be a ::Mutations::Outcome descendant." unless base < ::Mutations::Outcome
          # base.extend(DSL::Module) unless base.ancestors.include?(DSL::Module)
        end

        attr_reader :either

        def initialize(is_success, result, errors, inputs)
          super is_success, result, errors, inputs
          etherify
        end

        def eitherify!
          calc = EitherCalculator.new
          calc.outcome = self
          @either = calc.calculate
        end

        def right?
          @either.is_a?(Right)
        end

        def left?
          @either.is_a?(Left)
        end
      end
    end
  end
end
