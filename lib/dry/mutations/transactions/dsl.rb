module Dry
  module Mutations
    module Transactions # :nodoc:
      # http://dry-rb.org/gems/dry-transaction/basic-usage/
      # save_user = Dry.Transaction(container: Container) do
      #   step :process
      #   step :validate
      #   step :persist
      # end
      module DSL # :nodoc:
        def chain **params
          return enum_for(:chain) unless block_given? # FIXME: Needed? Works? Remove?

          new(**params, &cb)
        end

        def move target, Λ = nil, **params
          binding.pry
          Λ ||= params.delete(:with)
          @container[target] = wrap(
            case
            when params[:method] then Λ.method(params.delete[:method].to_sym).to_proc
            when Λ.respond_to?(:to_proc) then Λ
            when Λ.respond_to?(:call) then Λ.method(:call).to_proc
            else fail ArgumentError, "The executor given can not be executed (forgot to specify :method param?)"
            end, **params
          )
        end
        alias_method :mutate, :move
        alias_method :transform, :move
        alias_method :validate, :move
      end

      class CommandSet < ::Dry::Transaction::DSL # :nodoc:
        extend DSL

        def initialize(**params, &cb)
          @options = params
          @container = {}

          ::Kernel.binding.pry
          instance_eval(&cb)

          super(container: Container(@container)) do
            @container.each { |name, _| step name }
          end
          @options = nil
        end

        def to_s
          "CommandSet"
        end
      end
    end
  end
end
