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
  let!(:defaulted) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Pipe

      required do
        string :name
      end
      optional do
        integer :age, default: 42
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

  context 'default value is being set on no input' do
    let(:input) { { name: 'test' } }
    let(:output) { defaulted.new(input) }
    let(:expected) { ::Dry::Mutations::Utils.Hash(name: 'test', age: 42) }

    it 'sets the value of age to default' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end

  context 'default value does not override given' do
    let(:input) { { name: 'test', age: 84 } }
    let(:output) { defaulted.new(input) }
    let(:expected) { ::Dry::Mutations::Utils.Hash(name: 'test', age: 84) }

    it 'sets the value of age to default' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end
end
