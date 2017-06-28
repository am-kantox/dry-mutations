require 'spec_helper'

describe Dry::Mutations::Extensions::Command do
  let!(:command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Sieve

      schema(::Dry::Validation.Form do
        required(:fst_req) { filled? > str? }
        required(:snd_req) { filled? > str? }

        optional(:fst_opt) { filled? > str? }
        optional(:snd_opt) { filled? > str? }

        rule(opt_supplied: %i|fst_opt snd_opt|) do |fst_opt, snd_opt|
          fst_opt.filled? | snd_opt.filled?
        end
      end)
    end
  end

  context 'check none optionals' do
    let(:input) { { fst_req: 'First Required', snd_req: 'Second Required' } }
    let(:output) { command.new(input) }
    let(:expected) { ::Dry::Mutations::Utils.Hash(input) }
    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).not_to be_success
      expect(output.run.errors.keys).to eq(%w|opt_supplied|)
    end
  end

  context 'check both optionals' do
    let(:input) do
      { fst_req: 'First Required', snd_req: 'Second Required',
        fst_opt: 'First Optional', snd_opt: 'Second Optional' }
    end
    let(:output) { command.new(input) }
    let(:expected) { ::Dry::Mutations::Utils.Hash(input) }
    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end

  context 'check first optionals' do
    let(:input) do
      { fst_req: 'First Required', snd_req: 'Second Required',
        fst_opt: 'First Optional' }
    end
    let(:output) { command.new(input) }
    let(:expected) { ::Dry::Mutations::Utils.Hash(input) }
    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end

  context 'check both optionals' do
    let(:input) do
      { fst_req: 'First Required', snd_req: 'Second Required',
        snd_opt: 'Second Optional' }
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
