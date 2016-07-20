require 'spec_helper'

describe Dry::Mutations::Extensions::Command do
  let(:default_input) do
    {
      name: 'John',
      amount: 42,

      e1: '', e2: '1', e3: 'Just regular string',

      age: 35,
      emails: [
        { email: 'john@kantox.com', type: 'work' },
        { email: 'john@gmail.com', type: 'personal' }
      ],

      # NB: NOT YET IMPLEMENTED BECAUSE I DOUBT HOW :()
      arr_lvl_0: [
        { arr_lvl_2_val: 'a' },
        { arr_lvl_2_val: 'b' },
        { arr_lvl_2_val: 'c' }
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
      prepend ::Dry::Mutations::Extensions::Command

      required do
        string :name, max_length: 5
        integer :amount

        with_options empty: true do |empty|
          empty.string :e1
          empty.string :e2
          empty.string :e3
        end

        array :emails do
          string :email
          string :type
        end
      end

      optional do
        integer :age, min: 10, max: 100, nils: true
        array :arr_lvl_0 do
          string :arr_lvl_2_val, max_length: 3
        end
        array :arr_lvl_0_val do
          integer
        end
        # FIXME: deeply nested hashes fail to return proper error path:
        #        try to swap `:hsh_lvl_1_val` and `:hsh_lvl_1` and run tests
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

  let!(:raising_command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command

      required do
        integer :amount
      end
      def execute
        amount / 0
      end
    end
  end

  let!(:dummy_command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Dummy

      required do
        integer :amount
      end
    end
  end

  let(:output) { simple_command.new(input) }
  let(:expected) { ::Dry::Mutations::Utils.Hash(input) }

  before do
    # puts '—' * 60
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

  context 'dummy executor (validate only)' do
    let(:input) { { amount: 42 } }
    let(:dummy_output) { dummy_command.new(input) }
    it 'processes the input properly' do
      expect(dummy_output).to be_is_a(::Mutations::Command)
      expect(dummy_output.run).to be_success
      expect(dummy_output.run.result).to eq(expected)
    end
  end

  context 'simple hash without optionals' do
    let!(:input) { default_input.reject { |k, _| k == :age } }
    it 'does not require optionals in input' do
      expect(output.run).to be_success
    end
  end

  context 'date coercion works' do
    let!(:input) { { today: Date.today.strftime } }
    let!(:command) do
      Class.new(::Mutations::Command) do
        prepend ::Dry::Mutations::Extensions::Command

        required do
          date :today
        end

        def execute
          @inputs
        end
      end
    end

    it 'coerces input to be a date' do
      expect(command.(input)).to be_success
      expect(command.(input).value[:today]).to eq(Date.today)
    end
  end

  context 'integer coercion works' do
    let!(:input) { { amount: '42' } }
    let!(:command) do
      Class.new(::Mutations::Command) do
        prepend ::Dry::Mutations::Extensions::Command

        required do
          integer :amount
        end

        def execute
          @inputs
        end
      end
    end

    it 'coerces input to be an integer' do
      pending "For unknown reason it’s not working in the current implementation"
      expect(command.(input)).to be_success
      expect(command.(input).value[:amount]).to eq(42)
    end
  end

  context 'simple hash with nils permitted' do
    let!(:input) { default_input.merge(age: nil) }
    it 'does not require optionals in input' do
      expect(output.run).to be_success
    end
  end

  context 'simple hash with nils not permitted' do
    let!(:input) { default_input.merge(amount: nil) }
    it 'does not require optionals in input' do
      expect(output.run).not_to be_success
      expect(output.run.errors.size).to eq 1
      expect(output.messages.map(&:text)).to match_array(["must be filled"])
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

  context 'raising command' do
    it 'handles exceptions' do
      expect { raising_command.run(amount: 5) }.not_to raise_exception
      expect { raising_command.run(amount: 0) }.not_to raise_exception

      expect(raising_command.run(amount: 0)).not_to be_success
      expect(raising_command.run(amount: 0).errors.symbolic).to eq('♻' => :runtime_exception)
      expect(raising_command.run(amount: 0).errors.message).to eq('♻' => 'divided by 0')
    end
  end

  context 'call interface: success' do
    let(:input) { default_input }
    it 'processes the input properly' do
      expect(output.call).to be_right
      expect(output.call.value).to eq(expected)
    end
  end

  context 'call interface: failure' do
    let(:input) { default_input.merge name: 'John Smith', amount: :not_int, age: 1 }
    it 'processes the input properly' do
      expect(output.call).to be_left
      expect(output.call.value.values.count).to eq(3)
    end
  end

  context 'call class interface: success' do
    let(:input) { default_input }
    it 'processes the input properly' do
      expect(simple_command.call(input)).to be_right
      expect(simple_command.call(input).value).to eq(expected)
    end
  end

  context 'call class interface: failure' do
    let(:input) { default_input.merge name: 'John Smith', amount: :not_int, age: 1 }
    it 'processes the input properly' do
      expect(simple_command.call(input)).to be_left
      expect(simple_command.call(input).value.values.count).to eq(3)
    end
  end

  context 'to_proc interface: success' do
    let(:input) { [default_input] * 2 }
    it 'processes the input properly' do
      expect(input.map(&simple_command).size).to eq(2)
      expect(input.map(&simple_command).map(&:value).first).to eq(::Dry::Mutations::Utils.Hash(default_input))
    end
  end

  context 'factory interface: success' do
    # rubocop:disable Style/ClassAndModuleChildren
    class ::Dry::Mutations::MyMutationsCommand < ::Mutations::Command
      prepend ::Dry::Mutations::Extensions::Command

      required do
        string :name, max_length: 5
      end

      def execute
        @inputs
      end
    end
    # rubocop:enable Style/ClassAndModuleChildren

    it 'processes the input properly' do
      expect(MyMutationsCommand(name: 'John').value).to eq(::Dry::Mutations::Utils.Hash(name: 'John'))
    end
  end
end
