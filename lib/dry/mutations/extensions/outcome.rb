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
              value.success? ? Right(value.result) : Left(value.errors)
            end
          end
        end

        class Matcher # :nodoc:
          SUCCESS = Dry::Matcher::Case.new(
            match: ->(value) { value.right? },
            resolve: ->(value) { value.either.value }
          )

          # rubocop:disable Style/Lambda
          # rubocop:disable Style/BlockDelimiters
          FAILURE = Dry::Matcher::Case.new(
            match: -> (value, *patterns) {
              value.left? && (patterns.none? || (patterns & value.either.value.keys).any?)
            },
            resolve: -> (value) { value.either.value }
          )
          # rubocop:enable Style/BlockDelimiters
          # rubocop:enable Style/Lambda

          # Build the matcher
          def self.!
            Dry::Matcher.new(success: SUCCESS, failure: FAILURE)
          end

          private_constant :SUCCESS
          private_constant :FAILURE
        end

        def self.prepended base
          fail ArgumentError, "Can not prepend #{self.class} to #{base.class}: base class must be a ::Mutations::Outcome descendant." unless base < ::Mutations::Outcome
        end

        attr_reader :either

        def initialize(is_success, result, errors, inputs)
          super is_success, result, errors, inputs
          etherify!
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

        def value
          @either.value
        end

        def match
          fail 'Call to Outcome#match requires a block passed.' unless block_given?
          Matcher.!.(self, &Proc.new)
        end
      end
    end
  end
end
