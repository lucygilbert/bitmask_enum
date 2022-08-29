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

  create_table :prefix_test_models do |t|
    t.integer :attribs
  end

  create_table :suffix_test_models do |t|
    t.integer :attribs
  end

  create_table :include_nil_handler_test_models do |t|
    t.integer :attribs
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

FLAGS = %i[flag flag2 flag3].freeze

class TestModel < ActiveRecord::Base
  bitmask_enum attribs: FLAGS
end

class PrefixTestModel < ActiveRecord::Base
  bitmask_enum attribs: FLAGS, flag_prefix: 'pre'
end

class SuffixTestModel < ActiveRecord::Base
  bitmask_enum attribs: FLAGS, flag_suffix: 'post'
end

class IncludeNilHandlerTestModel < ActiveRecord::Base
  bitmask_enum attribs: FLAGS, nil_handling: :include
end
