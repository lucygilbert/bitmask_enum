require "bitmask_enum/version"
require 'active_record'

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

  def bitmask_enum(definition, flag_prefix: nil, flag_suffix: nil)
    validation_error = validate_definition(definition)
    raise BitmaskEnumInvalidError.new(validation_error) if validation_error.present?

    attribute, flags = definition.first
    flag_count = flags.size

    flags.each_with_index do |flag, i|
      flag_label = "#{flag_prefix}#{flag}#{flag_suffix}"
      define_flag_check_method(attribute, flag_label, i)
      define_flag_toggle_method(attribute, flag_label, i)
      define_flag_on_method(attribute, flag_label, i)
      define_flag_off_method(attribute, flag_label, i)
      define_class_flag_scopes(attribute, flag_label, flag_count, i)
    end

    define_flag_settings_hash_method(attribute, flags)
    define_enabled_flags_array_method(attribute, flags)
    define_class_flag_values_method(attribute, flags)
  end

  private

  def validate_definition(definition)
    return 'must be a hash' unless definition.is_a?(Hash)

    return 'must have one key' if definition.keys.size != 1

    flags = definition.first[1]
    return if flags.is_a?(Array) && flags.all? { |f| is_text?(f) }

    'must provide a symbol or string array of flags'
  end

  def is_text?(value)
    (value.is_a?(Symbol) || value.is_a?(String)) && value.size > 0
  end

  def define_flag_check_method(attribute, flag_label, i)
    check_for_method_conflict!(attribute, "#{flag_label}?")
    define_method("#{flag_label}?") { self[attribute] & 1 << i > 0 }
  end

  def define_flag_toggle_method(attribute, flag_label, i)
    check_for_method_conflict!(attribute, "#{flag_label}!")
    define_method("#{flag_label}!") { update!(attribute => self[attribute] ^ 1 << i) }
  end

  def define_flag_on_method(attribute, flag_label, i)
    method_name = "enable_#{flag_label}!"
    check_for_method_conflict!(attribute, method_name)
    define_method(method_name) { update!(attribute => self[attribute] | 1 << i) }
  end

  def define_flag_off_method(attribute, flag_label, i)
    method_name = "disable_#{flag_label}!"
    check_for_method_conflict!(attribute, method_name)
    define_method(method_name) { update!(attribute => self[attribute] & ~(1 << i)) }
  end

  def define_class_flag_scopes(attribute, flag_label, flag_count, i)
    enabled_method_name = "#{flag_label}_enabled"
    check_for_method_conflict!(attribute, enabled_method_name, klass_method: true)
    self.class_eval %(
      scope :#{enabled_method_name}, -> do
        where('#{attribute}' => #{values_for_bitmask_flag_index(:on, i, flag_count)})
      end
    )

    disabled_method_name = "#{flag_label}_disabled"
    check_for_method_conflict!(attribute, disabled_method_name, klass_method: true)
    self.class_eval %(
      scope :#{disabled_method_name}, -> do
        where('#{attribute}' => #{values_for_bitmask_flag_index(:off, i, flag_count)})
      end
    )
  end

  def define_flag_settings_hash_method(attribute, flags)
    method_name = "#{attribute}_settings"
    check_for_method_conflict!(attribute, method_name)
    define_method(method_name) do
      flags.each_with_index.each_with_object({}) do |(flag, i), settings|
        settings[flag] = self[attribute] & 1 << i > 0
      end
    end
  end

  def define_enabled_flags_array_method(attribute, flags)
    check_for_method_conflict!(attribute, attribute)
    define_method(attribute) do
      flags.each_with_index.select do |flag, i|
        self[attribute] & 1 << i > 0
      end.map(&:first)
    end
  end

  def define_class_flag_values_method(attribute, flags)
    check_for_method_conflict!(attribute, attribute, klass_method: true)
    singleton_class.send(:define_method, attribute) { flags }
  end

  def check_for_method_conflict!(attribute, method_name, klass_method: false)
    if klass_method
      if dangerous_class_method?(method_name)
        raise_bitmask_conflict_error!(
          ActiveRecord.name, self.name, attribute, method_name, klass_method
        )
      elsif method_defined_within?(method_name, ActiveRecord::Relation)
        raise_bitmask_conflict_error!(
          ActiveRecord::Relation.name, self.name, attribute, method_name, klass_method
        )
      end
    else
      if dangerous_attribute_method?(method_name)
        raise_bitmask_conflict_error!(
          ActiveRecord.name, self.name, attribute, method_name, klass_method
        )
      elsif bitmask_enum_method_already_defined?(method_name)
        raise_bitmask_conflict_error!(
          defined_bitmask_enum_methods[method_name],
          self.name,
          attribute,
          method_name,
          klass_method
        )
      end
    end

    defined_bitmask_enum_methods[method_name] = attribute
  end

  def bitmask_enum_method_already_defined?(method_name)
    defined_bitmask_enum_methods.include?(method_name)
  end

  def defined_bitmask_enum_methods
    @defined_bitmask_enum_methods ||= {}
  end

  def raise_bitmask_conflict_error!(source, klass, attribute, method_name, klass_method)
    raise BitmaskEnumMethodConflictError.new(source, klass, attribute, method_name, klass_method)
  end

  def values_for_bitmask_flag_index(setting, i, flag_count)
    comparator = setting == :on ? :> : :==
    (0...(1 << flag_count)).select { |x| (x & 1 << i).send(comparator, 0) }
  end
end

ActiveRecord::Base.extend(BitmaskEnum)
