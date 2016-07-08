require 'spec_helper'

describe Dry::Mutations::Command do
  let(:mixed_input) do
    {
      name: 'John',
      amount: 42
    }
  end

  let!(:mixed_command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Command

      required do
        string :name, max_length: 5
      end

      schema do
        required(:amount).filled(:int?, gt?: 0)
      end

      def execute
        @inputs
      end
    end
  end

  let(:output) { mixed_command.new(mixed_input) }
  let(:expected) { ::Dry::Mutations::Utils.Hash(mixed_input) }
  let(:errors) { output.run.errors }

  context 'it works' do
    let(:input) { mixed_input }
    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end

  context 'it rejects bad input' do
    let(:mixed_input) { { name: 'Aleksei', amount: -42 } }
    it 'generates schema errors' do
      expect(output.run).not_to be_success

      expect(errors.keys).to match_array(%w(name amount))
      expect(errors.values.map(&:predicate)).to match_array(%i(gt? max_size?))
    end
  end
end
