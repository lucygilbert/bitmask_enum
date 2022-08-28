# frozen_string_literal: true

require 'bundler/setup'
require 'bitmask_enum'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

ActiveRecord::Schema.define do
  create_table :test_models do |t|
    t.integer :attribs
    t.integer :other_int
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
