require 'spec_helper'

describe Dry::Mutations::Extensions::Command do
  let!(:command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Sieve

      required { integer :amount }
      optional do
        string :name, discard_empty: true
        integer :value, discard_empty: true
        array :arr, discard_empty: true do
          integer
        end
        hash :hash, discard_empty: true do
          integer :a
        end
        string :nil, discard_empty: true
      end
    end
  end

  context 'check with values' do
    let(:input) { { amount: 42, name: 'John', value: 100, arr: [1, 2, 3], hash: { a: 42 }, nil: 'nil' } }
    let(:output) { command.new(input) }
    let(:expected) { ::Dry::Mutations::Utils.Hash(input) }
    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end

  context 'check without values' do
    let(:input) { { amount: 42, name: '', value: 0, arr: [], hash: {}, nil: nil } }
    let(:output) { command.new(input) }
    let(:expected) { { 'amount' => 42, 'value' => 0 } }
    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end
end
