require 'dry-transaction'

require 'dry/mutations/transactions/container'
require 'dry/mutations/transactions/dsl'

module Dry
  module Mutations # :nodoc:
    def self.Transaction(**params, &cb)
      Transactions::CommandSet.new(**params, &cb).call
    end
  end
end
