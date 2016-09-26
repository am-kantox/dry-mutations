require 'spec_helper'

describe Dry::Mutations::Extensions::Command do
  let!(:command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Sieve

      required do
        integer :integer_value
        date    :date_value
        boolean :bool_value
      end
    end
  end

  context 'coercion is silently done' do
    let(:input) { { integer_value: '42', date_value: '2016-01-01', bool_value: 'true' } }
    let(:output) { command.new(input) }
    let(:expected) { ::Dry::Mutations::Utils.Hash(integer_value: 42, date_value: Date.parse('2016-01-01'), bool_value: true) }

    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end
end
