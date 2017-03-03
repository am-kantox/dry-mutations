require 'spec_helper'

describe Dry::Mutations::Extensions::Command do
  let(:mixed_input) do
    {
      name: 'John',
      amount1: 42,
      amount2: 3.14
    }
  end

  let!(:mixed_command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Sieve

      required do
        string :name, max_length: 5
      end

      schema do
        # required(:amount).filled(:int?, gt?: 0)
        required(:amount1).value(type?: Integer)
        required(:amount2) { model?(Float) }
      end
    end
  end

  let!(:dry_mixed_schema) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Sieve
      required do
        integer :age
        schema :user, UserSchema
        float :pi
      end
    end
  end

  let(:output) { command.new(input) }
  let(:expected) { ::Dry::Mutations::Utils.Hash(input) }
  let(:errors) { output.run.errors }

  context 'it works' do
    let(:input) { mixed_input }
    let(:command) { mixed_command }
    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end

  context 'it rejects bad input' do
    let(:input) { { name: 'Aleksei', amount1: 3.14, amount2: 42 } }
    let(:command) { mixed_command }
    it 'generates schema errors' do
      expect(output.run).not_to be_success

      expect(errors.keys).to match_array(%w(name amount1 amount2))
      expect(errors.values.map(&:dry_message).map(&:predicate)).to match_array(%i(type? max_size? model?))
    end
  end

  context 'it loads the external dry schema' do
    let(:input) do
      {
        user: {
          name: 'Aleksei',
          address: { street: 'c/Marina 16', city: 'Barcelona' }
        },
        age: 43,
        pi: 3.14159265
      }
    end
    let(:command) { dry_mixed_schema }
    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end

  context 'it validates against the external dry schema' do
    let(:input) do
      {
        user: {
          name: 'John',
          address: { street: 'c/Marina 16', city: 'Barcelona' }
        },
        age: 43
      }
    end
    let(:command) { dry_mixed_schema }
    it 'rejects the input properly' do
      expect(output.run).to_not be_success
      expect(errors.keys).to match_array(%w|user.name pi|)
    end
  end
end
