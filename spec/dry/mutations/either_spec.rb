require 'spec_helper'

describe Dry::Mutations::Extensions::Command do
  let(:right_input) { { name: 'John', amount: 42 } }
  let(:left_input) { { name: 'John Donne', amount: -500 } }

  let!(:either_command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command

      required do
        string :name, max_length: 5
      end

      schema do
        required(:amount).filled(:int?, gt?: 0)
      end

      def execute
        @inputs
      end
    end
  end

  let(:output)        { either_command.new(right_input) }
  let(:right_outcome) { output.run }
  let(:left_outcome)  { either_command.new(left_input).run }
  let(:expected)      { ::Dry::Mutations::Utils.Hash(right_input) }

  context 'it works' do
    let(:input) { right_input }
    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(right_outcome).to be_right
      expect(right_outcome.either.value).to eq(expected)
      expect(right_outcome.match { |m| m.success(&:keys) }).to match_array(%w(amount name))
      expect(right_outcome.match { |m| m.failure(&:keys) }).to be_nil
    end
  end

  context 'it fails on wrong input' do
    let(:input) { left_input }
    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(left_outcome).to be_left
      expect(left_outcome.either.value.keys).to match_array(%w(amount name))
      expect(left_outcome.match { |m| m.failure(&:keys) }).to match_array(%w(amount name))
      expect(left_outcome.match { |m| m.failure('amount', &:keys) }).to match_array(%w(amount name))
      expect(left_outcome.match { |m| m.failure('non_existing', &:keys) }).to be_nil
      expect(left_outcome.match { |m| m.success(&:keys) }).to be_nil
    end
  end
end
