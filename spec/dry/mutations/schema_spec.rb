require 'spec_helper'

describe Dry::Mutations::Extensions::Command do
  let!(:command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Sieve

      schema(::Dry::Validation.Form {})

      schema do
        required(:integer_value).filled(:int?, gt?: 0)
        required(:date_value).filled(:date?)
        required(:bool_value).filled(:bool?)
      end

      schema type: :form do
        required(:integer_value_nc).filled(:int?, gt?: 0)
        required(:date_value_nc).filled(:date?)
        required(:bool_value_nc).filled(:bool?)
      end

      required do
        integer :forty_two
        string :hello
      end
    end
  end

  context 'coercion is silently done' do
    let(:input) do
      {
        hello: :world, forty_two: '42',
        integer_value: '42', date_value: '2016-01-01', bool_value: 'true',
        integer_value_nc: '42', date_value_nc: '2016-01-01', bool_value_nc: 'true'
      }
    end
    let(:output) { command.new(input) }
    let(:expected) do
      ::Dry::Mutations::Utils.Hash(
        forty_two: 42, hello: 'world',
        integer_value: 42, date_value: Date.parse('2016-01-01'), bool_value: true,
        integer_value_nc: 42, date_value_nc: Date.parse('2016-01-01'), bool_value_nc: true
      )
    end

    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end
end
