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

      def self.extend_outcome(whatever, host)
        whatever.tap do |outcome|
          outcome.instance_variable_set(:@host, host)
          outcome.extend(Module.new do
            def host
              @host
            end
          end)
        end
      end
    end
  end
end
