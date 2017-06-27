module Dry
  module Mutations
    module Utils # :nodoc:
      def self.Λ input, **params
        case
        when params[:method] then input.method(params.delete[:method].to_sym).to_proc
        when input.respond_to?(:to_proc) then input.to_proc
        when input.respond_to?(:call) then input.method(:call).to_proc
        else fail ArgumentError, "The executor given can not be executed (forgot to specify :method param?)"
        end
      end

      # Lazy detector for Hashie::Mash
      #   TODO: Make it possible to choose friendly hash implementation
      USE_HASHIE_MASH = Falsey?(ENV['PLAIN_HASHES'], explicit: false) && begin
        require 'hashie/mash'
        require 'hashie/dash'
        require 'hashie/extensions/indifferent_access'
        ::Mutations::ErrorHash.prepend Hashie::Extensions::IndifferentAccess
        true
      rescue LoadError => e
        $stderr.puts [
          '[DRY] Could not find Hashie::Mash.',
          'You probably want to install it / add it to your Gemfile.',
          "Error: [#{e.message}]."
        ].join($/)
      end
    end
  end
end
