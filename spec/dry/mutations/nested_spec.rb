require 'spec_helper'

describe Dry::Mutations::Extensions::Command do
  let!(:command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Sieve

      NestedSchema = Dry::Validation.Form do
        required(:name).filled(:str?)
        optional(:age).filled(:int?, gt?: 0)
        optional(:nick).filled(:str?)
      end

      schema(::Dry::Validation.Form do
        required(:id).filled(:int?, gt?: 0)
        optional(:properties).schema(NestedSchema)
      end)
    end
  end

  context 'coercion is silently done' do
    let(:input) do
      { id: 1, properties: { name: 'Aleksei', age: 43 } }
    end
    let(:output) { command.new(input) }
    let(:expected) do
      ::Dry::Mutations::Utils.Hash(
        id: 1, properties: { name: 'Aleksei', age: 43 }
      )
    end

    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end
end
