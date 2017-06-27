# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dry/mutations/version'

Gem::Specification.new do |spec|
  spec.name          = 'dry-mutations'
  spec.version       = Dry::Mutations::VERSION
  spec.authors       = ['Aleksei Matiushkin']
  spec.email         = ['aleksei.matiushkin@kantox.com']

  spec.summary       = 'Mutations gem interface implemented with `dry-rb`’s validation schemas.'
  spec.description   = <<-DESC
    Mutations gem interface implemented with `dry-rb`’s validation schemas.
  DESC
  spec.homepage      = 'http://github.com/am-kantox/dry-mutations'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  fail 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)
  # spec.metadata['allowed_push_host'] = 'https://gemfury.com'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}, &File.method(:basename))
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'activerecord', '< 5', '>= 3.2'  # prevent mutations to require activerecord 5

  spec.add_dependency 'activesupport', '< 5', '>= 3.2' # prevent mutations to require activesupport 5
  spec.add_dependency 'mutations', '~> 0.8'
  spec.add_dependency 'hashie', '~> 3'

  spec.add_dependency 'dry-validation', '~> 0.10'
  spec.add_dependency 'dry-transaction', '~> 0.10'
end
