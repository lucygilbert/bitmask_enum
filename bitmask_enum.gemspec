# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bitmask_enum/version'

Gem::Specification.new do |spec|
  spec.name          = 'bitmask_enum'
  spec.version       = BitmaskEnum::VERSION
  spec.authors       = ['Lucy Gilbert']
  spec.email         = ['lucygilbert01@gmail.com']

  spec.summary       = 'A bitmask enum attribute for ActiveRecord'
  spec.homepage      = 'https://github.com/lucygilbert/bitmask_enum'
  spec.license       = 'MIT'

  raise 'RubyGems 2+ required to guard against public gem pushes' unless spec.respond_to?(:metadata)

  spec.metadata['allowed_push_host'] = 'TODO: Set to http://mygemserver.com'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  end
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4'

  spec.add_dependency 'activerecord', '>= 4.2', '<=7.0'
  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.35'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.12'
  spec.add_development_dependency 'sqlite3', '~> 1.4'
end
