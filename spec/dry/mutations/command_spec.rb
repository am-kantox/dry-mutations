require 'spec_helper'

describe Dry::Mutations::Command do
  let(:default_input) do
    {
      name: 'John',
      amount: 42,
      age: 35,

      # NB: NOT YET IMPLEMENTED BECAUSE I DOUBT HOW :()
      arr_lvl_0: [
        {},
        {}
      ],
      arr_lvl_0_val: [1, 2, 3],

      hsh_lvl_0: {
        hsh_lvl_1: {
          hsh_lvl_2_val: 42
        },
        hsh_lvl_1_val: 'this should be at least 2 symbols'
      }
    }
  end

  let!(:simple_command) do
    Class.new(::Mutations::Command) do
      required do
        string :name, max_length: 5
        integer :amount
      end
      optional do
        integer :age, min: 10, max: 100
        array :arr_lvl_0 do
          string :arr_lvl_2_val, max_length: 3
        end
        array :arr_lvl_0_val do
          integer
        end
        hash :hsh_lvl_0 do
          string :hsh_lvl_1_val, min_length: 2
          hash :hsh_lvl_1 do
            integer :hsh_lvl_2_val, in: [42]
          end
        end
      end
      def execute
        @inputs
      end
    end
  end

  let(:output) { simple_command.new(input) }
  let(:expected) { ::Dry::Mutations::Utils.Hash(input) }

  before do
    puts '—' * 60
    # puts output.messages.inspect
    # puts '—' * 60
  end

  context 'simple hashes' do
    let(:input) { default_input }
    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end

  context 'erroneous hash' do
    let!(:input) { default_input.merge name: 'John Smith', amount: :not_int, age: 1 }
    it 'fails on incorrect input' do
      expect(output.run).not_to be_success
      expect(output.run.errors.size).to eq 3
      expect(output.messages.map(&:text)).to match_array(
        ['size cannot be greater than 5', 'must be an integer', 'must be greater than or equal to 10']
      )
      expect { output.run! }.to raise_error(::Mutations::ValidationException)
    end
  end

  context 'hash to be coerced' do
    let(:input) { default_input.merge age: '35' }
    it 'coerces the input properly' do
      pending 'Relies on coercion in dry, NYI'
      expect(output.run).to be_success
    end
  end

  context 'hash to be stripped' do
    let(:input) { default_input.merge name: ' o_o ' }
    it 'strips input strings' do
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected.merge('name' => 'o_o'))
    end
  end

  context 'nested hashes are ok' do
    let(:input) do
      default_input.tap do |inp|
        inp[:arr_lvl_0_val] << 'error very long entry'
        inp[:hsh_lvl_0][:hsh_lvl_1_val] = 'e'
        inp[:hsh_lvl_0][:hsh_lvl_1][:hsh_lvl_2_val] = 0
      end
    end
    it 'strips input strings' do
      expect(output.run).not_to be_success
      expect(output.run.errors.symbolic).to eq(
                          "arr_lvl_0_val.3" => :int?,
        "hsh_lvl_0.hsh_lvl_1.hsh_lvl_2_val" => :in,
                  "hsh_lvl_0.hsh_lvl_1_val" => :min_length
      )
    end
  end
end
