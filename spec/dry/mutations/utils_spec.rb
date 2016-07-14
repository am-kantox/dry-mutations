require 'spec_helper'

describe Dry::Mutations::Utils do
  context 'helper methods' do
    let!(:input) do
      {
        name: 'John',
        min_size?: 10,
        max_size?: 20,
        min_length: 11,
        max_length: 21
      }
    end

    it 'stringifies hash keys without hashie/mash' do
      expect(Dry::Mutations::Utils.Hash(key: 42)).to eq('key' => 42)
    end

    it 'maps parameters correctly' do
      expect(Dry::Mutations::Utils.Guards(**input)).to eq(min_length: 10, max_length: 20)
      expect(Dry::Mutations::Utils.Guards(:min_size?, :max_size?, **input)).to eq(min_length: 10, max_length: 20)
      expect(Dry::Mutations::Utils.Guards(:min_length, :max_length, **input)).to eq(min_size?: 11, max_size?: 21)
      expect(Dry::Mutations::Utils.Guards([:min_length, :max_length], **input)).to eq(min_size?: 11, max_size?: 21)
    end

    it 'camelizes and snakeizes' do
      expect(Dry::Mutations::Utils.Snake('AaaBbbCcc::Ddd::Eee_Ff')).to eq('aaa_bbb_ccc__ddd__eee_ff')
      expect(Dry::Mutations::Utils.Snake('AaaBbb')).to eq('aaa_bbb')
      expect(Dry::Mutations::Utils.SnakeSafe('AaaBbb', %w(aaa_bbb))).to eq('aaa_bbb_1')
      expect(Dry::Mutations::Utils.SnakeSafe('AaaBbb', %w(aaa_bbb aaa_bbb_1 aaa_bbb_3))).to eq('aaa_bbb_2')
    end
  end
end
