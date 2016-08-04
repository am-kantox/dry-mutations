module Dry
  module Mutations
    module Extensions
      module Sieve # :nodoc:
        def execute
          inputs
        end
      end

      module Pipe # :nodoc:
        def execute
          case
          when respond_to?(:raw_inputs) then raw_inputs
          when instance_variable_defined?(:@raw_inputs) then instance_variable_get(:@raw_inputs)
          else inputs
          end
        end
      end

      # rubocop:disable Style/ConstantName
      Dummy = ENV['USE_SIEVE_AS_DUMMY'] ? Sieve : Pipe
      # rubocop:enable Style/ConstantName

      module Wrapper # :nodoc:
        include Dummy
        prepend(Module.new do
                  def execute
                    { Utils.Snake(self.class, short: true, symbolize: true) => super }
                  end
                end)
      end
    end
  end
end
