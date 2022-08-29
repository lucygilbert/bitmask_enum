# frozen_string_literal: true

module BitmaskEnum
  # Handles the bitmask enum's user-provided options
  # @api private
  class Options
    attr_reader :flag_prefix, :flag_suffix, :nil_handling

    def initialize(options)
      @flag_prefix = options[:flag_prefix].nil? ? '' : "#{options[:flag_prefix]}_"
      @flag_suffix = options[:flag_suffix].nil? ? '' : "_#{options[:flag_suffix]}"
      @nil_handling = options[:nil_handling].to_sym
    end
  end
end
