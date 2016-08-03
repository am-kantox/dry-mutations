require 'mutations'

require 'dry-validation'
require 'dry-transaction'
require 'dry-matcher'
require 'dry-monads'

require 'dry/mutations/version'
require 'dry/mutations/utils'
require 'dry/mutations/monkeypatches'
require 'dry/mutations/predicates'
require 'dry/mutations/errors'
require 'dry/mutations/dsl'
require 'dry/mutations/extensions'
require 'dry/mutations/transactions'

require 'dry/mutations/globals'

module Dry
  # A dry implementation of mutations interface introduced by
  #   [Jonathan Novak](mailto:jnovak@gmail.com) in
  #   [`mutations` gem](http://github.com/cypriss/mutations).
  #
  # Basically, all the old mutations syntax is supported, plus
  #   native [`dry-validation`](http://github.com/dry-rb/dry-validation)
  #   schemas moight be used to describe validation rules.
  module Mutations
    def self.inject target
      %i(Schema Blocks Types Weirdo).each do |mod|
        target.singleton_class.prepend ::Dry::Mutations::DSL.const_get(mod)
      end
    end

    DSL::Types::Nested.extend DSL::Module
    ::Mutations::Command.prepend Extensions::Command if Utils.Truthy?(ENV['GLOBAL_DRY_MUTATIONS'])
  end
end
