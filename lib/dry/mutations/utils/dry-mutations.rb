# rubocop:disable Style/FileName
require 'dry-types'
# rubocop:enable Style/FileName

module Dry
  module Mutations
    module Utils # :nodoc:
      DRY_TYPES = ::Dry::Types.type_keys.grep(/\A[^.]+\z/)
      DRY_TO_MUTATIONS = {
        min_size?:    :min_length,
        max_size?:    :max_length,
        format?:      :matches,
        inclusion?:   :in, # deprecated in Dry
        included_in?: :in,
        gteq?:        :min,
        lteq?:        :max
      }.freeze
      MUTATIONS_TO_DRY = DRY_TO_MUTATIONS.invert.merge(default: :default?).freeze

      ##########################################################################
      COERCIBLE_STRING = ::Dry::Types::Constructor.new(
        ::Dry::Types['strict.string'], fn: ->(v) { v.to_s.strip }
      )

      def self.RawInputs *args
        args.inject(Utils.Hash({})) do |h, arg|
          h.merge! case arg
                   when Hash then arg
                   when ::Dry::Monads::Either::Right then arg.value
                   when ::Dry::Monads::Either::Left then fail ArgumentError.new("Can’t accept Left value: #{args.inspect}.")
                   else fail ArgumentError.new("All arguments must be hashes. Given: #{args.inspect}.") unless arg.is_a?(Hash)
                   end
        end
      end

      # Fuzzy converts params between different implementaions
      def self.Guards *keys, **params
        return {} if params.empty? || params[:empty] # Mutations `empty?` guard takes precedence on all others

        keys = params.keys if keys.empty?
        keys.flatten! # allow array to be passed as the only parameter

        map = [DRY_TO_MUTATIONS, MUTATIONS_TO_DRY].detect do |h|
          (h.keys & keys).any?
        end || Hash.new(&ITSELF)

        map.values_at(*keys).zip(keys.map(&params.method(:[])))
           .to_h
           .tap { |h| h.delete(nil) }
      end

      def self.Type type, **params
        case Snake(type)
        when 'string'
          if Falsey?(params[:strip])
            :str?
          else
            # TODO: this silently coerces everything to be a string
            #       when `param[:strip]` is specified. This is likely OK, though.
            COERCIBLE_STRING
          end
        when 'date'
          ::Dry::Types::Constructor.new(
            ::Dry::Types['strict.date'], fn: ->(v) { v.is_a?(Date) ? v : (Date.parse(v.to_s) rescue v) }
          )
        when 'integer'
          ::Dry::Types::Constructor.new(
            ::Dry::Types['strict.int'], fn: ->(v) { v.is_a?(Integer) ? v : (v.to_i rescue v) }
          )
        when 'boolean'
          ::Dry::Types::Constructor.new(
            ::Dry::Types['strict.bool'], fn: ->(v) do
              case v
              when TrueClass, FalseClass then v
              when NilClass then false
              when String
                case
                when Falsey?(v) then false
                when Truthy?(v) then true
                end
              end
            end
          )
        when ->(t) { DRY_TYPES.include?(t) } then :"#{type}?"
          # else type implicitly return `nil` here TODO
        end
      end

      def self.smart_send receiver, *args, **params
        params.empty? ? receiver.__send__(*args) : receiver.__send__(*args, **params)
      end
    end
  end
end
