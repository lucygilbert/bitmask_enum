# frozen_string_literal: true

require 'active_record'
require 'bitmask_enum/attribute'
require 'bitmask_enum/errors'

# Adds support for bitmask enum attributes to ActiveRecord models.
module BitmaskEnum
  DEFAULT_BITMASK_ENUM_OPTIONS = {
    flag_prefix: nil,
    flag_suffix: nil,
    nil_handling: :include,
    validate: true
  }.freeze

  # Defines a bitmask enum and constructs the magic methods and method overrides for handling it.
  # @param params [Hash] Hash with first key/value being the attribute name and an array of flags,
  #   the remaining keys being options.
  #   - `flag_prefix`: Symbol or string that prefixes all the created method names for flags joined with an underscore
  #   - `flag_suffix`: Symbol or string that suffixes all the created method names for flags joined with an underscore
  #   - `nil_handling`: Symbol or string signaling behaviour when handling nil attribute values. Options are:
  #     - `include`: Treat nil as 0 and include in queries, this is the default.
  #   - `validate`: Boolean to apply attribute validation. Attributes will validate that they are
  #     less than the number of flags squared (number of flags squared - 1 is the highest valid bitmask value).
  #     Defaults to `true`.
  def bitmask_enum(params)
    validation_error = validate_params(params)
    raise BitmaskEnumInvalidError, validation_error if validation_error.present?

    attribute, flags = params.shift
    flags = flags.map(&:to_sym)
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
