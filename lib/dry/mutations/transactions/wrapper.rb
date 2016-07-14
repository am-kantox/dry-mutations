module Dry
  module Mutations
    module Transactions # :nodoc:
      class Wrapper # :nodoc:
        def initialize(**params)
          (@wrappers = params).each do |name, λ|
            fail ArgumentError, "Wrapper’s constructor requires hash of { name ⇒ λ(proc, value) }" unless name.is_a?(Symbol) && λ.is_a?(Proc)
            singleton_class.send :define_method, name do |value, naked|
              -> { λ.(value, naked.()) }
            end
          end
        end

        def wrap λ, **params
        end

        private_class_method :new
      end

      class Options < Wrapper
        OPTIONS = {
          failure: ->(value, λ) do
            result = λ.()
            Utils.Falsey?(value) ? result : Right(nil)
          end
        }.freeze
        def initialize
        end
      end
    end
  end
end
