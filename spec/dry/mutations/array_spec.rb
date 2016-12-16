require 'spec_helper'

describe Dry::Mutations::Extensions::Command do
  let!(:command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Sieve

      required do
        array :ages do
          integer :age
        end
        array :names, class: String
        array :important_nils, nils: true, class: NilClass
      end
      optional do
        array :values, class: DummyTestClass
        array :nils, nils: true
      end
    end
  end

  context 'array is processed properly' do
    let(:input) do
      {
        ages: [{ age: 42 }],
        names: %w|John Eduard|,
        important_nils: [nil],
        values: [DummyTestClass.new],
        nils: []
      }
    end
    let(:output) { command.new(input) }
    let(:expected) { ::Dry::Mutations::Utils.Hash(input) }

    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end
end
