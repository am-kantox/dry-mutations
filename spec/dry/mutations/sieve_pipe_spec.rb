require 'spec_helper'

describe Dry::Mutations::Extensions::Command do
  let!(:input) { { name: 'John', amount: 42 } }

  let!(:validator) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command

      required do
        string :name, max_length: 5
      end
    end
  end

  let!(:transformer) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command

      def execute
        {
          name: "#{inputs.name}ny",
          amount: inputs.amount / 2
        }
      end
    end
  end

  context 'sieve validator' do
    let(:sieve_validator) do
      validator.prepend ::Dry::Mutations::Extensions::Sieve
    end
    it 'processes the input properly' do
      expect(sieve_validator.run!(input)).to eq(::Dry::Mutations::Utils.Hash(name: 'John'))
    end
  end

  context 'pipe validator' do
    let(:pipe_validator) do
      validator.prepend ::Dry::Mutations::Extensions::Pipe
    end
    it 'processes the input properly' do
      expect(pipe_validator.run!(input)).to eq(::Dry::Mutations::Utils.Hash(input))
    end
  end

  context 'hole transformer' do
    let(:hole_transformer) do
      transformer.prepend ::Dry::Mutations::Extensions::Hole
    end
    it 'processes the input properly' do
      expect(hole_transformer.run!(input)).to eq(name: 'Johnny', amount: 21)
    end
  end

  context 'wrapper transformer' do
    let(:wrapper_transformer) do
      transformer.prepend ::Dry::Mutations::Extensions::Hole
      transformer.prepend ::Dry::Mutations::Extensions::Wrapper
    end
    it 'processes the input properly' do
      expect(wrapper_transformer.run!(input).values.first).to eq(name: 'Johnny', amount: 21)
    end
  end
end
