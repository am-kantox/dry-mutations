module Dry
  module Mutations
    module DSL
      BRICKS = %i(Schema Blocks Types Weirdo).freeze.each

      module Module # :nodoc:
        def self.extended base
          BRICKS.each do |mod|
            base.singleton_class.prepend ::Dry::Mutations::DSL.const_get(mod)
          end
        end

        def self.included base
          BRICKS.each do |mod|
            base.prepend ::Dry::Mutations::DSL.const_get(mod)
          end
        end
      end
    end
  end
end
