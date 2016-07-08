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
  end
end
