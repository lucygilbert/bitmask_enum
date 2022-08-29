# frozen_string_literal: true

module BitmaskEnum
  NIL_HANDLING_OPTIONS = [:include].freeze

  # Handles the bitmask enum's user-provided options
  # @api private
  class Options
    attr_reader :flag_prefix, :flag_suffix, :nil_handling

    def initialize(options)
      @nil_handling = options[:nil_handling].to_sym
      unless NIL_HANDLING_OPTIONS.include?(@nil_handling)
        raise BitmaskEnumInvalidError, "#{@nil_handling} is not a valid nil handling option"
      end

      @flag_prefix = options[:flag_prefix].nil? ? '' : "#{options[:flag_prefix]}_"
      @flag_suffix = options[:flag_suffix].nil? ? '' : "_#{options[:flag_suffix]}"
    end
  end
end
