require 'spec_helper'

describe Dry::Mutations::Extensions::Command do
  let(:command) do
    Class.new(::Mutations::Command) do
      prepend ::Dry::Mutations::Extensions::Command
      prepend ::Dry::Mutations::Extensions::Sieve

      required do
        array :ages do
          integer :age
        end
        array :names, class: String
        array :important_nils, nils: true, class: NilClass
      end
      optional do
        array :values, class: DummyTestClass
        array :nils, nils: true
      end
    end
  end

  context 'array is processed properly' do
    let(:input) do
      {
        ages: [{ age: 42 }],
        names: %w|John Eduard|,
        important_nils: [nil],
        values: [DummyTestClass.new],
        nils: []
      }
    end
    let(:output) { command.new(input) }
    let(:expected) { ::Dry::Mutations::Utils.Hash(input) }

    it 'processes the input properly' do
      expect(output).to be_is_a(::Mutations::Command)
      expect(output.run).to be_success
      expect(output.run.result).to eq(expected)
    end
  end

  context 'ActiveRecord::Relation' do
    let!(:ars_command) do
      Class.new(::Mutations::Command) do
        prepend ::Dry::Mutations::Extensions::Command

        schema(Dry::Mutations.Schema do
          required(:slaves1).filled(relation?: Slave)
        end)

        required do
          array :slaves2, class: Slave
        end

        def execute
          slaves1.map(&:master).uniq | slaves2.map(&:master).uniq
        end
      end
    end

    let!(:arm_command) do
      Class.new(::Mutations::Command) do
        prepend ::Dry::Mutations::Extensions::Command

        required do
          model :master, class: Master
        end

        def execute
          master.slaves
        end
      end
    end

    let(:master) { Master.create!(whatever: 'I am master') }
    let!(:slaves) do
      1.upto(10).map do |i|
        Slave.create!(whatever: "I am slave ##{i} :(", master_id: master.id)
      end
    end

    context 'is processed properly on input' do
      let(:input) { { slaves1: master.slaves, slaves2: master.slaves } }
      let(:output) { ars_command.new(input) }

      it "should handle ActiveRecord::Relation as an array income" do
        expect(output).to be_is_a(::Mutations::Command)
        expect(output.run).to be_success
        expect(output.run.result.size).to eq(1)
        expect(output.run.result).to match_array([master])
      end
    end

    context 'is processed properly on output' do
      let(:input) { { master: master } }
      let(:output) { arm_command.new(input) }

      it "should handle ActiveRecord::Relation as an array outcome" do
        expect(output).to be_is_a(::Mutations::Command)
        expect(output.run).to be_success
        expect(output.run.result).to eq(slaves)
        expect(output.run.result).to be_is_a(ActiveRecord::Relation)
      end
    end
  end
end
