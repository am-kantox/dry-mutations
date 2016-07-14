module Dry
  module Mutations
    module Transactions # :nodoc:
      # @param [Hash] moves
      def self.Container(moves)
        Class.new do
          extend Dry::Container::Mixin

          def self.add_move name, λ = nil
            fail ArgumentError, "Move needs a symbolic name, given: [#{name.inspect}]" unless name.is_a?(Symbol)

            λ ||= Proc.new if block_given?
            fail ArgumentError, 'Move needs a Proc instance or a block passed' unless λ.is_a?(Proc) # && λ.arity == 1

            register name, λ
          end

          moves.each do |name, λ|
            add_move name.to_sym, λ
          end
        end
      end
    end
  end
end
