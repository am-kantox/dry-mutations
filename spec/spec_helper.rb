$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'

require 'dry/mutations'

class DummyTestClass; end

require 'simplecov'
SimpleCov.start
