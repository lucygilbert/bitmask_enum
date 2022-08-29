# frozen_string_literal: true

module BitmaskEnum
  # Handles nil attribute values
  # @api private
  class NilHandler
    def initialize(handling_option)
      @handling_option = handling_option
    end

    # Handles nil when evaling the attribute
    # @param [String] Name of the attribute
    # @return [String] Code string to handle a nil attribute according to the handling option
    def in_attribute_eval(attribute)
      select_handling(
        attribute,
        include: ->(attrib) { "(self['#{attrib}'] || 0)" }
      )
    end

    # Handles nil for an array of values for the attribute
    # @param [Array] Array of integers representing values of the attribute
    # @return [Array] Array of integers representing values of the attribute, now corrected for nil values
    def in_array(array)
      select_handling(
        array,
        include: ->(arr) { arr << nil }
      )
    end

    private

    def select_handling(value, handling_actions)
      action = handling_actions[@handling_option] || handling_actions[:include]

      action.call(value)
    end
  end
end
