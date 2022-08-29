# frozen_string_literal: true

require 'bitmask_enum/errors'

module BitmaskEnum
  # Checks for method conflicts on the model
  # @api private
  class ConflictChecker
    def initialize(model, attribute, defined_enum_methods)
      @model = model
      @attribute = attribute
      @defined_enum_methods = defined_enum_methods
    end

    # Check if the method name is dangerous or already defined on the class
    # @param method_name [String] Name of the method
    def check_class_method!(method_name)
      if @model.dangerous_class_method?(method_name)
        raise_bitmask_conflict_error!(ActiveRecord.name, method_name, klass_method: true)
      elsif @model.method_defined_within?(method_name, ActiveRecord::Relation)
        raise_bitmask_conflict_error!(ActiveRecord::Relation.name, method_name, klass_method: true)
      end
    end

    # Check if the method name is dangerous or already defined on the instance, or defined by another bitmask enum
    # @param method_name [String] Name of the method
    def check_instance_method!(method_name)
      if @model.dangerous_attribute_method?(method_name)
        raise_bitmask_conflict_error!(ActiveRecord.name, method_name)
      elsif @defined_enum_methods.include?(method_name)
        raise_bitmask_conflict_error!(@defined_enum_methods[method_name], method_name)
      end

      @defined_enum_methods[method_name] = @attribute
    end

    private

    def raise_bitmask_conflict_error!(source, method_name, klass_method: false)
      raise BitmaskEnumMethodConflictError.new(source, @model.name, @attribute, method_name, klass_method)
    end
  end
end
