module Dry
  module Mutations
    module Extensions
      module Outcome # :nodoc:
        include Dry::Monads::Either::Mixin

        class EitherCalculator # :nodoc:
          include Dry::Monads::Either::Mixin

          attr_reader :outcome, :either

          def initialize(outcome)
            @either = Right(@outcome = outcome).bind do |value|
              value.success? ? Right(value.result) : Left(value.errors)
            end
          end
        end

        class Matcher # :nodoc:
          SUCCESS = Dry::Matcher::Case.new(
            match: ->(value) { value.right? },
            resolve: ->(value) { value.either.value }
          )

          # rubocop:disable Style/BlockDelimiters
          FAILURE = Dry::Matcher::Case.new(
            match: -> (value, *patterns) {
              value.left? && (patterns.none? || (patterns & value.either.value.keys).any?)
            },
            resolve: -> (value) { value.either.value }
          )
          # rubocop:enable Style/BlockDelimiters

          # Build the matcher
          def self.!
            Dry::Matcher.new(success: SUCCESS, failure: FAILURE)
          end

          private_constant :SUCCESS
          private_constant :FAILURE
        end

        def self.prepended base
          fail ArgumentError, "Can not prepend #{self} to #{base}: base class must be a ::Mutations::Outcome descendant." unless base <= ::Mutations::Outcome
        end

        def either
          @either ||= EitherCalculator.new(self).either
        end

        def right?
          either.is_a?(Right)
        end

        def left?
          either.is_a?(Left)
        end

        def value
          either.value
        end

        def match
          fail 'Call to Outcome#match requires a block passed.' unless block_given?
          Matcher.!.(self, &Proc.new)
        end
      end

      ::Mutations::Outcome.prepend Outcome unless ::Mutations::Outcome.ancestors.include?(Outcome)

      def self.Outcome input
        case input
        when ::Mutations::Outcome then input
        when ::Dry::Monads::Either::Left
          ::Mutations::Outcome.new(false, nil, input.value, nil)
        when ::Dry::Monads::Either::Right
          ::Mutations::Outcome.new(true, input.value, nil, nil)
        when ->(inp) { inp.respond_to?(:success?) }
          ::Mutations::Outcome.new(input.success?, input.success? && input, input.success? || input, nil)
        else fail TypeError.new("Wrong input passed to Outcome(): [#{input.inspect}]")
        end
      end

      def self.Outcome! input
        outcome = Outcome(input)
        raise ::Mutations::ValidationException.new(outcome.errors) unless outcome.success?
        outcome.value
      end
    end
  end
end
