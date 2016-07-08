require 'mutations'
require 'dry-validation'

require 'dry/mutations/version'
require 'dry/mutations/utils'
require 'dry/mutations/monkeypatches'
require 'dry/mutations/predicates'
require 'dry/mutations/errors'
require 'dry/mutations/dsl'
require 'dry/mutations/command'

module Dry
  # A dry implementation of mutations interface introduced by
  #   [Jonathan Novak](mailto:jnovak@gmail.com) in
  #   [`mutations` gem](http://github.com/cypriss/mutations).
  #
  # Basically, all the old mutations syntax is supported, plus
  #   native [`dry-validation`](http://github.com/dry-rb/dry-validation)
  #   schemas moight be used to describe validation rules.
  module Mutations
  end
end
