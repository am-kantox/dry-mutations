require 'spec_helper'

# rubocop:disable Metrics/BlockLength
describe Dry::Mutations::Transactions do
  let(:input) { { name: 'John' } }
  let(:input2) { { age: 42 } }
  let(:expected) { { name: 'John Donne', value: 42 } }

  let!(:command1) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Hole

      def execute
        @inputs.tap { |inp| inp[:name] << ' Donne' }
      end
    end
  end
  let!(:command2) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      required { string :name, max_length: 10 }

      def execute
        @inputs.merge(amount: 42)
      end
    end
  end
  let!(:command3) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Sieve
      required do
        string :name, max_length: 10
        integer :amount, max: 42
      end
      optional do
        integer :age
      end
    end
  end
  let!(:command0) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      def execute
        fail StandardError, "Hi, I am failed. Sorry for that."
      end
    end
  end

  context 'it works' do
    let(:result) do
      c1 = command1
      c2 = command2
      c3 = command3
      Class.new do
        extend ::Dry::Mutations::Transactions::DSL

        # We need inplace blocks to create chains.
        #   It makes sense mostly for `tee` and `try`
        chain do
          tranquilo c1
          validate c2
          transform c3
        end
      end
    end
    it 'processes the input properly' do
      expect(result.(input)).to eq(::Dry::Monads::Right(Hashie::Mash.new(amount: 42, name: "John Donne")))
    end
    context 'many hashes' do
      let(:command2) do
        Class.new(::Mutations::Command) do
          prepend ::Dry::Mutations::Extensions::Command
          required do
            string :name, max_length: 10
            integer :age, min: 41
          end

          def execute
            @inputs.merge(amount: 42)
          end
        end
      end

      it 'accepts many hashes for the input' do
        expect(result.(input, input2)).to eq(
          ::Dry::Monads::Right(Hashie::Mash.new(age: 42, amount: 42, name: "John Donne"))
        )
      end
    end
  end

  context 'nested chains work' do
    let(:result) do
      c1 = command1
      c2 = command2
      c3 = command3

      child = Class.new do
        extend ::Dry::Mutations::Transactions::DSL
        chain { validate c2 }
      end

      Class.new do
        extend ::Dry::Mutations::Transactions::DSL

        # We need inplace blocks to create chains.
        #   It makes sense mostly for `tee` and `try`
        chain do
          tranquilo c1
          chain child
          chain do
            validate c3
          end
        end
      end
    end
    it 'processes the input properly' do
      expect(result.(input)).to eq(::Dry::Monads::Right(Hashie::Mash.new(amount: 42, name: "John Donne")))
    end
  end

  context 'it returns Left on error' do
    let(:result) do
      c1 = command1
      c0 = command0
      c3 = command3
      Class.new do
        extend ::Dry::Mutations::Transactions::DSL

        # We need inplace blocks to create chains.
        #   It makes sense mostly for `tee` and `try`
        chain do
          transform c1
          try c0, catch: StandardError
          transform c3
        end
      end
    end
    it 'processes the input properly' do
      expect(result.(input)).to be_left
    end
  end
end
# rubocop:enable Metrics/BlockLength
