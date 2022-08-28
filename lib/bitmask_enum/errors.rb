# frozen_string_literal: true

module BitmaskEnum
  class BitmaskEnumInvalidError < ArgumentError
    def initialize(detail)
      super("BitmaskEnum definition is invalid: #{detail}")
    end
  end

  class BitmaskEnumMethodConflictError < ArgumentError
    def initialize(source, klass, attribute, method_name, klass_method)
      super(
        'BitmaskEnum method definition is conflicting: ' \
        "#{klass_method ? 'class ' : ''}method: #{method_name} " \
        "for enum: #{attribute} in class: #{klass} is already defined by: #{source}"
      )
    end
  end
end
