require 'spec_helper'

describe Dry::Mutations::Command do
  context 'simple hashes' do
    let(:simple_command) do
      Class.new(::Mutations::Command) do
        required do
          string :name, max_length: 10
          integer :amount, min: 10, max: 100
        end
        optional do
          integer :age
        end
        def execute
          @inputs
        end
      end
    end
    let(:input) do
      { name: 'John', amount: 42, age: '35' }
    end

    it 'processes the input properly' do
      expect(simple_command.new(input)).to be_is_a(::Mutations::Command)
      expect(simple_command.run(input)).to eq('key' => 42)
    end
  end
end
