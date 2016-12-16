$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'

require 'dry/mutations'

class DummyTestClass; end

UserSchema = ::Dry::Validation.Schema do
  required(:name).value(format?: /^A/)
  required(:address).schema do
    required(:street).filled
    required(:city).filled
  end
end

require 'simplecov'
SimpleCov.start
