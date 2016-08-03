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
end
