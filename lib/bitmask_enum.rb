# frozen_string_literal: true

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
    raise BitmaskEnumInvalidError, validation_error if validation_error.present?

    attribute, flags = definition.first

    flags.each_with_index do |flag, flag_index|
      per_flag_methods(
        attribute, "#{flag_prefix}#{flag}#{flag_suffix}", flag_index, flags.size
      )
    end

    flag_settings_hash_method(attribute, flags)
    enabled_flags_array_method(attribute, flags)

    class_flag_values_method(attribute, flags)
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

  def per_flag_methods(attribute, flag_label, flag_index, flags_count)
    flag_check_method(attribute, flag_label, flag_index)
    flag_toggle_method(attribute, flag_label, flag_index)
    flag_on_method(attribute, flag_label, flag_index)
    flag_off_method(attribute, flag_label, flag_index)

    class_flag_enabled_scope(attribute, flag_label, flag_index, flags_count)
    class_flag_disabled_scope(attribute, flag_label, flag_index, flags_count)
  end

  def flag_check_method(attribute, flag_label, flag_index)
    flag_method(attribute, "#{flag_label}?") { (self[attribute] & (1 << flag_index)).positive? }
  end

  def flag_toggle_method(attribute, flag_label, flag_index)
    flag_method(attribute, "#{flag_label}!") { update!(attribute => self[attribute] ^ (1 << flag_index)) }
  end

  def flag_on_method(attribute, flag_label, flag_index)
    flag_method(attribute, "enable_#{flag_label}!") { update!(attribute => self[attribute] | (1 << flag_index)) }
  end

  def flag_off_method(attribute, flag_label, flag_index)
    flag_method(attribute, "disable_#{flag_label}!") { update!(attribute => self[attribute] & ~(1 << flag_index)) }
  end

  def flag_method(attribute, method_name, &block)
    check_for_instance_method_conflict!(attribute, method_name)

    define_method(method_name, &block)
  end

  def class_flag_enabled_scope(attribute, flag_label, flag_index, flags_count)
    enabled_method_name = "#{flag_label}_enabled"
    values_for_bitmask = values_for_bitmask_flag_index(:on, flag_index, flags_count)

    check_for_class_method_conflict!(attribute, enabled_method_name)

    class_eval %(
      scope :#{enabled_method_name}, -> do              # scope :flag_enabled, -> do
        where('#{attribute}' => #{values_for_bitmask})  #   where('attribs' => [1, 3, 5])
      end                                               # end
    ), __FILE__, __LINE__ - 4
  end

  def class_flag_disabled_scope(attribute, flag_label, flag_index, flags_count)
    disabled_method_name = "#{flag_label}_disabled"
    values_for_bitmask = values_for_bitmask_flag_index(:off, flag_index, flags_count)

    check_for_class_method_conflict!(attribute, disabled_method_name)

    class_eval %(
      scope :#{disabled_method_name}, -> do             # scope :flag_disabled, -> do
        where('#{attribute}' => #{values_for_bitmask})  #   where('attribs' => [0, 2, 4])
      end                                               # end
    ), __FILE__, __LINE__ - 4
  end

  def flag_settings_hash_method(attribute, flags)
    method_name = "#{attribute}_settings"
    check_for_instance_method_conflict!(attribute, method_name)
    define_method(method_name) do
      flags.each_with_index.each_with_object({}) do |(flag, flag_index), settings|
        settings[flag] = (self[attribute] & (1 << flag_index)).positive?
      end
    end
  end

  def enabled_flags_array_method(attribute, flags)
    check_for_instance_method_conflict!(attribute, attribute)
    define_method(attribute) do
      flags.each_with_index.select do |_flag, flag_index|
        (self[attribute] & (1 << flag_index)).positive?
      end.map(&:first)
    end
  end

  def class_flag_values_method(attribute, flags)
    check_for_class_method_conflict!(attribute, attribute)
    singleton_class.send(:define_method, attribute) { flags }
  end

  def check_for_class_method_conflict!(attribute, method_name)
    if dangerous_class_method?(method_name)
      raise_bitmask_conflict_error!(
        ActiveRecord.name, name, attribute, method_name, klass_method: true
      )
    elsif method_defined_within?(method_name, ActiveRecord::Relation)
      raise_bitmask_conflict_error!(
        ActiveRecord::Relation.name, name, attribute, method_name, klass_method: true
      )
    end
  end

  def check_for_instance_method_conflict!(attribute, method_name)
    if dangerous_attribute_method?(method_name)
      raise_bitmask_conflict_error!(ActiveRecord.name, name, attribute, method_name)
    elsif bitmask_enum_method_already_defined?(method_name)
      raise_bitmask_conflict_error!(
        defined_bitmask_enum_methods[method_name],
        name,
        attribute,
        method_name
      )
    end

    defined_bitmask_enum_methods[method_name] = attribute
  end

  def bitmask_enum_method_already_defined?(method_name)
    defined_bitmask_enum_methods.include?(method_name)
  end

  def defined_bitmask_enum_methods
    @defined_bitmask_enum_methods ||= {}
  end

  def raise_bitmask_conflict_error!(source, klass, attribute, method_name, klass_method: false)
    raise BitmaskEnumMethodConflictError.new(source, klass, attribute, method_name, klass_method)
  end

  def values_for_bitmask_flag_index(setting, flag_index, flag_count)
    comparator = setting == :on ? :> : :==
    (0...(1 << flag_count)).select { |x| (x & (1 << flag_index)).send(comparator, 0) }
  end
end

ActiveRecord::Base.extend(BitmaskEnum)
