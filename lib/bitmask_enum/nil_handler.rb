# frozen_string_literal: true

module BitmaskEnum
  class NilHandler
    def initialize(handling_option)
      @handling_option = handling_option
    end

    def in_attribute_eval(attribute)
      select_handling(
        attribute,
        include: ->(attrib) { "(self['#{attrib}'] || 0)" }
      )
    end

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
