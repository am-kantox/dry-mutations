module Dry
  module Mutations
    module Errors
      class ErrorAtom < ::Mutations::ErrorAtom # :nodoc:
        %i(predicate path text rule args options).each do |mm|
          define_method(mm) do |*args, &cb|
            @dry_message.send mm, *args, &cb
          end
        end

        attr_reader :dry_message

        def initialize(key, error_symbol, dry_message, options = {})
          super key, Utils::DRY_TO_MUTATIONS[error_symbol] || error_symbol, options
          @dry_message = dry_message
        end

        def self.patch_message_set(set)
          return nil if set.empty?

          fail TypeError, "Expected: ::Dry::Validation::MessageSet; got: #{set.class}" unless set.is_a?(::Dry::Validation::MessageSet)

          set.map.with_index.with_object(::Mutations::ErrorHash.new) do |(msg, idx), memo|
            # key = msg.path.join('.')
            last = msg.path.pop
            tail = msg.path.inject(memo) { |acc, curr| acc[curr.to_s] ||= ::Mutations::ErrorHash.new }
            tail[last] = case tail[last]
                         when ErrorAtom then ::Mutations::ErrorArray.new << tail[last.to_s]
                         when NilClass then ::Mutations::ErrorArray.new
                         when ::Mutations::ErrorArray then tail[last.to_s]
                         end
            key = msg.respond_to?(:predicate) ? msg.predicate : last
            text = msg.respond_to?(:text) ? msg.text : msg.to_s
            tail[last.to_s] << new(last, key, msg, message: text, index: idx)
            # memo[key] = new(key, msg.predicate, msg, message: msg.text, index: idx)
          end
        end
      end
    end
  end
end
