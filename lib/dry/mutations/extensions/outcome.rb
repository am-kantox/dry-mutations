module Dry
  module Mutations
    module Extensions # :nodoc:
      module Either # :nodoc:
        include Dry::Monads::Either::Mixin

        class EitherCalculator # :nodoc:
          include Dry::Monads::Either::Mixin

          attr_reader :outcome, :either

          # rubocop:disable Style/VariableNumber
          def initialize(outcome)
            @∨ = outcome.class.instance_variable_get(:@∨)
            @either = Right(@outcome = outcome).bind do |value|
              value.public_send(@∨[:success]) ? Right(value.public_send(@∨[:right])) : Left(value.public_send(@∨[:left]))
            end
          end
          # rubocop:enable Style/VariableNumber
        end

        class Matcher # :nodoc:
          SUCCESS = Dry::Matcher::Case.new(
            match: ->(value) { value.right? },
            resolve: ->(value) { value.either.value }
          )

          FAILURE = Dry::Matcher::Case.new(
            match: ->(value, *patterns) {
              value.left? && (patterns.none? || (patterns & value.either.value.keys).any?)
            },
            resolve: ->(value) { value.either.value }
          )

          # Build the matcher
          def self.!
            Dry::Matcher.new(success: SUCCESS, failure: FAILURE)
          end

          private_constant :SUCCESS
          private_constant :FAILURE
        end

        # rubocop:disable Style/VariableNumber
        def self.prepended base
          λ = base.instance_methods.method(:include?)
          base.instance_variable_set(:@∨, {
            left:    %i|errors left|.detect(&λ),
            right:   %i|result output right|.detect(&λ),
            success: %i|success?|.detect(&λ)
          }.reject { |_, v| v.nil? }.merge(base.instance_variable_get(:@∨) || {}))
          fail ArgumentError, "Can not have #{self} #{__callee__} to #{base}: base class must look like an either." unless base.instance_variable_get(:@∨).size == 3
        end
        # rubocop:enable Style/VariableNumber
        singleton_class.send :alias_method, :included, :prepended

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
          fail "Call to #{self.class.name}#match requires a block passed." unless block_given?
          Matcher.!.(self, &Proc.new)
        end
      end

      def self.Either input
        case input
        when Class then input.prepend Either unless input.ancestors.include?(Either)
        when Module then input.include Either unless input.ancestors.include?(Either)
        else input.singleton_class.prepend Either unless input.singleton_class.ancestors.include?(Either)
        end
      end

      Either(::Mutations::Outcome)
      Either(::Dry::Validation::Result)

      def self.Outcome input
        case input
        when ::Mutations::Outcome then input
        when ::Dry::Monads::Either::Left
          ::Mutations::Outcome.new(false, nil, input.value, nil).tap do |outcome|
            ::Dry::Mutations::Utils.extend_outcome outcome, input.value.host
          end
        when ::Dry::Monads::Either::Right
          ::Mutations::Outcome.new(true, input.value, nil, nil).tap do |outcome|
            ::Dry::Mutations::Utils.extend_outcome outcome, input.value.host
          end
        when ->(inp) { inp.respond_to?(:success?) }
          ::Mutations::Outcome.new(input.success?, input.success? && input, input.success? || input, nil).tap do |outcome|
            ::Dry::Mutations::Utils.extend_outcome outcome, input.host if input.respond_to?(:host)
          end
        else fail TypeError.new("Wrong input passed to Outcome(): [#{input.inspect}]")
        end
      end

      def self.Outcome! input
        Outcome(input).tap do |outcome|
          fail ::Mutations::ValidationException.new(outcome.errors) unless outcome.success?
        end.value
      end
    end
  end
end
