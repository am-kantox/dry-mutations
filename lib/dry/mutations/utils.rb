module Dry
  module Mutations
    module Utils # :nodoc:
      FALSEY =  /\A#{Regexp.union(%w(0 false falsey no n)).source}\z/i
      TRUTHY =  /\A#{Regexp.union(%w(0 true truthy yes y)).source}\z/i

      def self.Falsey? input, explicit: true
        explicit ? input.to_s =~ FALSEY : input.to_s !~ TRUTHY
      end

      def self.Truthy? input, explicit: true
        explicit ? input.to_s =~ TRUTHY : input.to_s !~ FALSEY
      end

      # Lazy detector for Hashie::Mash
      #   TODO: Make it possible to choose friendly hash implementation
      USE_HASHIE_MASH = (ENV['PLAIN_HASHES'].to_s !~ /\A(1|yes|true)\z/i) && begin
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
      def self.Hash hash
        case
        when USE_HASHIE_MASH
          Kernel.const_get('::Hashie::Mash').new(hash)
        when hash.respond_to?(:with_indifferent_access)
          hash.with_indifferent_access
        else
          hash.map { |k, v| [k.to_s, v] }.to_h
        end
      end

      DRY_TO_MUTATIONS = {
        min_size?:    :min_length,
        max_size?:    :max_length,
        format?:      :matches,
        inclusion?:   :in, # deprecated in Dry
        included_in?: :in,
        gteq?:        :min,
        lteq?:        :max
      }.freeze
      MUTATIONS_TO_DRY = DRY_TO_MUTATIONS.invert.freeze

      # Fuzzy converts params between different implementaions
      def self.Guards *keys, **params
        return {} if params.empty? || params[:empty] # Mutations `empty?` guard takes precedence on all others

        keys.flatten! # allow array to be passed as the only parameter
        map = [DRY_TO_MUTATIONS, MUTATIONS_TO_DRY].detect do |h|
          (h.keys & (keys.empty? ? params.keys : keys)).any?
        end

        keys = map.keys if map && keys.empty?
        keys.zip(map.values_at(*keys).map(&params.method(:[])))
            .to_h
            .reject { |_, v| v.nil? }
      end

      def self.Type type, **params
        case type.to_s
        when 'string'
          Falsey?(params[:strip]) ? :str? : ::Dry::Types['strict.string'].constructor(&:strip)
        when 'integer' then :int?
        else :"#{type}?"
        end
      end

      def self.smart_send receiver, *args, **params
        params.empty? ? receiver.__send__(*args) : receiver.__send__(*args, **params)
      end
    end
  end
end
