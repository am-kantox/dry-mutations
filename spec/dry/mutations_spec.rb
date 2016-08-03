require 'spec_helper'

describe Dry::Mutations do
  it 'has a version number' do
    expect(Dry::Mutations::VERSION).not_to be nil
  end

  describe Dry::Mutations::Extensions do
    let!(:input) { {}.extend Module.new { def success?; true; end } }
    it 'provides a shortcut for fast schema creation' do
      expect(Schema()).to be_respond_to :call
    end
    it 'provides a shortcut for fast outcome creation' do
      expect(Outcome(input)).to be_is_a(::Mutations::Outcome)
      expect(Outcome(input).success?).to be_truthy
    end
    it 'provides a shortcut for fast banged outcome creation' do
      expect(Outcome!(input)).to be_empty
    end
  end

  describe '#Schema' do
    it 'generates a schema' do
      expect(Dry::Mutations.Schema).to respond_to(:call)
    end

    it 'gets the block' do
      schema = Dry::Mutations.Schema do
        required(:key) { str? }
      end
      expect(schema.call({})).not_to be_success
      expect(schema.call({key: 1})).not_to be_success
      expect(schema.call({key: '1'})).to be_success
    end

    describe 'mutations predicates' do
      it 'exposes the `model?` predicate' do
        schema = Dry::Mutations.Schema do
          optional(:decimal) { model?(BigDecimal) }
        end

        expect(schema.call({decimal: 2})).not_to be_success
        expect(schema.call({decimal: BigDecimal(2)})).to be_success
      end

      it 'exposes the `duck?` predicate' do
        schema = Dry::Mutations.Schema do
          optional(:stuff) { duck?([:succ]) }
        end

        expect(schema.call({stuff: Object.new})).not_to be_success
        expect(schema.call({stuff: 'I actually have a succ'})).to be_success
      end
    end
  end
end
