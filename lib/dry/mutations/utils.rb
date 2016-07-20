module Dry
  module Mutations
    module Utils # :nodoc:
      FALSEY =  /\A#{Regexp.union(%w(0 skip false falsey no n)).source}\z/i
      TRUTHY =  /\A#{Regexp.union(%w(1 use true truthy yes y)).source}\z/i

      def self.Falsey? input, explicit: true
        explicit ? input.to_s =~ FALSEY : input.to_s !~ TRUTHY
      end

      def self.Truthy? input, explicit: true
        explicit ? input.to_s =~ TRUTHY : input.to_s !~ FALSEY
      end

      def self.Snake(whatever, short: false, symbolize: false)
        result = whatever.to_s.split('::').map do |e|
          e.gsub(/(?<=[^\W_])(?=[A-Z])/, '_').downcase
        end
        result = short ? result.last : result.join('__')
        symbolize ? result.to_sym : result
      end

      def self.SnakeSafe(whatever, existing = [], update_existing: true, short: false, symbolize: false)
        result = Snake(whatever, short: short)
        str = loop do
          break result unless existing.include? result
          suffix = result[/(?<=_)\d+(?=\z)/]
          suffix.nil? ? result << '_1' : result[-suffix.length..-1] = (suffix.to_i + 1).to_s
        end.tap { |r| existing << r if update_existing }
        symbolize ? str.to_sym : str
      end

      def self.Camel(whatever)
        whatever.to_s.split('__').map do |s|
          s.gsub(/(?:\A|_)(?<letter>\w)/) { $~[:letter].upcase }
        end.join('::')
      end

      def self.Constant(whatever)
        ::Kernel.const_get(Camel(whatever))
      end

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
        true
      rescue LoadError => e
        $stderr.puts [
          '[DRY] Could not find Hashie::Mash.',
          'You probably want to install it / add it to your Gemfile.',
          "Error: [#{e.message}]."
        ].join($/)
      end

      # Converts a hash to a best available hash implementation
      #   with stringified keys, since `Mutations` expect hash
      #   keys to be strings.
      def self.Hash hash = {}
        case
        when USE_HASHIE_MASH
          Kernel.const_get('::Hashie::Mash').new(hash)
        when hash.respond_to?(:with_indifferent_access)
          hash.with_indifferent_access
        else
          hash.map { |k, v| [k.to_s, v] }.to_h
        end
      end

      ITSELF = ->(h, k) { h[k] = k }
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
        case type.to_s
        when 'string'
          if Falsey?(params[:strip])
            :str?
          else
            # TODO: this silently coerces everything to be a string
            #       when `param[:strip]` is specified. This is likely OK, though.
            ::Dry::Types::Constructor.new(
              ::Dry::Types['strict.string'], fn: ->(v) { v.to_s.strip }
            )
          end
        when 'date'
          ::Dry::Types::Constructor.new(
            ::Dry::Types['strict.date'], fn: ->(v) { v.is_a?(Date) ? v : (Date.parse(v.to_s) rescue v) }
          )
        when 'integer'
          :int?
          # FIXME: Why ints are not coercible?!
          #::Dry::Types::Constructor.new(
          #  ::Dry::Types['coercible.int'], fn: ->(v) { v.is_a?(Integer) ? v : (v.to_i rescue v) }
          #)
        when 'boolean' then :bool?
        else :"#{type}?"
        end
      end

      def self.smart_send receiver, *args, **params
        params.empty? ? receiver.__send__(*args) : receiver.__send__(*args, **params)
      end
    end
  end
end
