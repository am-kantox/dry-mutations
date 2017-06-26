require 'spec_helper'

describe Dry::Mutations::Extensions::Command do
  let(:command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Sieve

      # rubocop:disable Style/MultilineIfModifier
      NestedSchema = Dry::Validation.Form do
        required(:name).filled(:str?, min_size?: 3)
        optional(:age).filled(:int?, gt?: 0)
        optional(:nick).filled(:str?)
      end unless const_defined?('NestedSchema')
      # rubocop:enable Style/MultilineIfModifier

      schema(::Dry::Validation.Form do
        required(:id).filled(:int?, gt?: 0)
        optional(:properties).schema(NestedSchema)
      end)

      def validate
        add_error :"properties.name", :custom, 'Must be cool' unless properties.name == 'Aleksei'
      end
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

  context 'standard errors are nested properly' do
    let(:input) do
      { id: 1, properties: { name: '', age: 43 } }
    end
    let(:output) { command.new(input) }

    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).not_to be_success
      expect(output.run.errors).to be_is_a(Hash)
      expect(output.run.errors[:properties]).to be_is_a(Hash)
      expect(output.run.errors[:properties][:name].last.text).to eq("size cannot be less than 3")
    end
  end

  context 'custom errors are nested properly' do
    let(:input) do
      { id: 1, properties: { name: 'John', age: 43 } }
    end
    let(:output) { command.new(input) }
    let(:expected) do
      ::Dry::Mutations::Utils.Hash(
        properties: { name: 'must be string' }
      )
    end

    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).not_to be_success
      expect(output.run.errors).to be_is_a(Hash)
      expect(output.run.errors[:properties]).to be_is_a(Hash)
      expect(output.run.errors[:properties]["name"].text).to eq("Must be cool")
    end
  end
end
