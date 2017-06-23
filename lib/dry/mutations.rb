require 'mutations'

require 'dry-validation'
require 'dry-transaction'
require 'dry-matcher'
require 'dry-monads'

require 'dry/mutations/monkeypatches'

require 'dry/mutations/version'
require 'dry/mutations/utils'
require 'dry/mutations/monkeypatches'
require 'dry/mutations/predicates'
require 'dry/mutations/errors'
require 'dry/mutations/dsl'
require 'dry/mutations/extensions'
require 'dry/mutations/transactions'
require 'dry/mutations/schema'

require 'dry/mutations/globals'
require 'dry/mutations/patches'

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
      DSL::BRICKS.each do |mod|
        target.singleton_class.prepend ::Dry::Mutations::DSL.const_get(mod)
      end
    end

    def self.Schema(input_processor: nil, type: :schema, **options, &block)
      type = :schema unless type && ::Dry::Mutations.const_defined?(type.to_s.capitalize)
      parent = ::Dry::Mutations.const_get(type.to_s.capitalize)
      ::Dry::Validation.Schema(parent, **options) do
        configure { config.input_processor = input_processor } if input_processor
        instance_exec(&block) if block
      end
    end

    DSL::Types::Nested.extend DSL::Module
    ::Mutations::Command.prepend Extensions::Command if Utils.Truthy?(ENV['GLOBAL_DRY_MUTATIONS'])
  end
end
