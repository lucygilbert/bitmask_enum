# frozen_string_literal: true

require 'active_record'
require 'bitmask_enum/attribute'
require 'bitmask_enum/errors'

module BitmaskEnum
  DEFAULT_BITMASK_ENUM_OPTIONS = {
    flag_prefix: nil,
    flag_suffix: nil
  }.freeze

  def bitmask_enum(params)
    validation_error = validate_params(params)
    raise BitmaskEnumInvalidError, validation_error if validation_error.present?

    attribute, flags = params.shift
    options = params
    merged_options = DEFAULT_BITMASK_ENUM_OPTIONS.merge(options.symbolize_keys)

    Attribute.new(self, attribute, flags, merged_options, defined_bitmask_enum_methods).construct!
  end

  private

  def validate_params(params)
    return 'must be a hash' unless params.is_a?(Hash)
    return 'attribute must be a symbol or string and cannot be empty' unless text?(params.first.first)

    flags = params.first[1]
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
