require 'spec_helper'

describe Dry::Mutations::Transactions do
  let(:input)    { { name: 'John' } }
  let(:expected) { { name: 'John Donne', value: 42 } }

  let!(:command1) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      required { string :name, max_length: 5 }

      def execute
        @inputs[:name] << ' Donne'
      end
    end
  end
  let!(:command2) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      required { string :name, max_length: 10 }

      def execute
        @inputs.merge(value: 42)
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
      c2 = command1
      c3 = command1
      ::Dry::Mutations.Transaction do
        mutate :command1, c1
        validate :command2, c2
        transform :command3, c3
      end
    end
    it 'processes the input properly' do
      expect(result.()).to eq([])
    end
  end
end
