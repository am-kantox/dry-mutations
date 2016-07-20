require 'spec_helper'

describe Dry::Mutations::Transactions do
  let(:input)    { { name: 'John' } }
  let(:expected) { { name: 'John Donne', value: 42 } }

  let!(:command1) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      required { string :name, max_length: 5 }

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
      required do
        string :name, max_length: 10
        integer :amount, max: 42
      end

      def execute
        @inputs
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
          tranquilo(::Dry::Transaction(container: container, step_adapters: step_adapters) do
            mutate c1, param: 42
          end, catch: StandardError)
          validate c2
          transform c3
        end
      end
    end
    it 'processes the input properly' do
      expect(result.(input)).to eq(::Dry::Monads::Right(Hashie::Mash.new(amount: 42, name: "John Donne")))
    end
  end
end
