module Dry
  module Mutations
    module Extensions
      module ErrorHash
        def message
          super.map.with_index(1) { |kv, i| "#{i}. " << kv.join(': ') }.join("\n")
        end
      end
    end
  end
end
