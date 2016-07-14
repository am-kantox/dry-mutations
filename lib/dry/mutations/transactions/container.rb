module Dry
  module Mutations
    module Transactions # :nodoc:
      Container = lambda do |whatever|
        whatever.respond_to?(:call) ? whatever : Utils.Constant(whatever).tap do |p|
          fail ArgumentError, "The argument must respond to :call, though #{k.inspect} passed." unless p.respond_to? :call
        end
      end

      # @param [Hash|Array] moves
      def self.Container_Legacy(moves)
        Class.new do
          extend Dry::Container::Mixin

          def self.add_move name, λ = nil
            fail ArgumentError, "Move needs a symbolic name, given: [#{name.inspect}]" unless name.is_a?(Symbol)

            λ ||= Proc.new if block_given?
            fail ArgumentError, 'Move needs a Proc instance or a block passed' unless λ.is_a?(Proc) # && λ.arity == 1

            puts "Container registering: #{name.inspect}"
            register name, λ
          end

          case moves
          when Array # array of [m, *args, cb]
            moves.each_with_object([]) do |(_, cb, args), names|
              args = args.dup
              receiver = args.shift
              params = loop.each_with_object({}) do |_, memo|
                break memo unless (h = args.detect { |arg| arg.is_a?(Hash) })
                memo.merge!(args.delete(h))
              end
              λ = case
                  when cb.nil? then Utils.Λ(receiver, **params)
                  when args.empty? then cb
                  else fail "NOT YET IMPLEMENTED" # ->(*more) { cb.(Utils.Λ(receiver, **params).(), *more) }
                  end
              add_move Utils.SnakeSafe(receiver, names, symbolize: true), λ
            end
          when Hash # name ⇒ λ
            moves.each do |name, λ|
              add_move name.to_sym, λ
            end
          else
            fail ArgumentError, "Container factory expects either Array or Hash instance; #{moves} was given."
          end
        end
      end
    end
  end
end
