# frozen_string_literal: true

require 'active_record'
require 'bitmask_enum/attribute'
require 'bitmask_enum/errors'

module BitmaskEnum
  DEFAULT_BITMASK_ENUM_OPTIONS = {
    flag_prefix: nil,
    flag_suffix: nil
  }.freeze

  def bitmask_enum(definition, options = {})
    validation_error = validate_definition(definition)
    raise BitmaskEnumInvalidError, validation_error if validation_error.present?

    attribute, flags = definition.first
    merged_options = options.symbolize_keys.merge(DEFAULT_BITMASK_ENUM_OPTIONS)

    Attribute.new(self, attribute, flags, merged_options, defined_bitmask_enum_methods).construct!
  end

  private

  def validate_definition(definition)
    return 'must be a hash' unless definition.is_a?(Hash)

    return 'must have one key' if definition.keys.size != 1

    flags = definition.first[1]
    return if flags.is_a?(Array) && flags.all? { |f| text?(f) }

    'must provide a symbol or string array of flags'
  end

  def text?(value)
    (value.is_a?(Symbol) || value.is_a?(String)) && value.size.positive?
  end

  def defined_bitmask_enum_methods
    @defined_bitmask_enum_methods ||= {}
  end
end

ActiveRecord::Base.extend(BitmaskEnum)
