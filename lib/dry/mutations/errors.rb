module Dry
  module Mutations
    module Errors
      class AnonymousTypeDetected < StandardError # :nodoc:
        attr_reader :type, :cause
        def initialize type, cause = nil
          @type = type
          @cause = cause
        end
      end

      class TypeError < StandardError # :nodoc:
      end

      class ChainExecutionError < StandardError # :nodoc:
        def initialize left
          super left.inspect # FIXME
        end
      end
    end
  end
end

require 'dry/mutations/errors/error_atom'
require 'dry/mutations/errors/error_compiler'
