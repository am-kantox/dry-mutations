module Dry
  module Mutations
    module Extensions
      module ErrorArray
        def message
          super.join(', ')
        end
      end
    end
  end
end
