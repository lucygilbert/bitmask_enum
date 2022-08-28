# frozen_string_literal: true

require 'bitmask_enum/conflict_checker'
require 'bitmask_enum/options'
require 'bitmask_enum/nil_handler'
require 'bitmask_enum/eval_scripts'

module BitmaskEnum
  class Attribute
    def initialize(model, attribute, flags, options, defined_enum_methods)
      @attribute = attribute
      @flags = flags
      @options = Options.new(options)
      @nil_handler = NilHandler.new(@options.nil_handling)
      @model = model
      @conflict_checker = ConflictChecker.new(model, attribute, defined_enum_methods)
    end

    def construct!
      @flags.each_with_index do |flag, flag_index|
        per_flag_methods("#{@options.flag_prefix}#{flag}#{@options.flag_suffix}", flag_index)
      end

      flag_settings_hash_method
      flag_getter_method
      flag_setter_method

      class_flag_values_method
    end

    private

    def per_flag_methods(flag_label, flag_index)
      flag_check_method(flag_label, flag_index)
      flag_toggle_method(flag_label, flag_index)
      flag_on_method(flag_label, flag_index)
      flag_off_method(flag_label, flag_index)

      class_flag_enabled_scope(flag_label, flag_index)
      class_flag_disabled_scope(flag_label, flag_index)
    end

    def flag_check_method(flag_label, flag_index)
      flag_method("#{flag_label}?", "(#{@nil_handler.in_attribute_eval(@attribute)} & #{1 << flag_index}).positive?")
    end

    def flag_toggle_method(flag_label, flag_index)
      flag_method(
        "#{flag_label}!",
        "update!('#{@attribute}' => #{@nil_handler.in_attribute_eval(@attribute)} ^ #{1 << flag_index})"
      )
    end

    def flag_on_method(flag_label, flag_index)
      flag_method(
        "enable_#{flag_label}!",
        "update!('#{@attribute}' => #{@nil_handler.in_attribute_eval(@attribute)} | #{1 << flag_index})"
      )
    end

    def flag_off_method(flag_label, flag_index)
      flag_method(
        "disable_#{flag_label}!",
        "update!('#{@attribute}' => #{@nil_handler.in_attribute_eval(@attribute)} & #{~(1 << flag_index)})"
      )
    end

    def flag_method(method_name, method_code)
      @conflict_checker.check_instance_method!(method_name)

      @model.class_eval EvalScripts.flag_method(method_name, method_code), __FILE__, __LINE__
    end

    def class_flag_enabled_scope(flag_label, flag_index)
      class_flag_scope("#{flag_label}_enabled", :on, flag_index)
    end

    def class_flag_disabled_scope(flag_label, flag_index)
      class_flag_scope("#{flag_label}_disabled", :off, flag_index)
    end

    def class_flag_scope(scope_name, setting, flag_index)
      comparator = setting == :on ? :> : :==
      values_for_bitmask = (0...(1 << @flags.size)).select { |x| (x & (1 << flag_index)).send(comparator, 0) }

      values_for_bitmask = @nil_handler.in_array(values_for_bitmask) if setting == :off

      @conflict_checker.check_class_method!(scope_name)

      @model.class_eval EvalScripts.flag_scope(scope_name, @attribute, values_for_bitmask), __FILE__, __LINE__
    end

    def flag_settings_hash_method
      method_name = "#{@attribute}_settings"

      @conflict_checker.check_instance_method!(method_name)

      flag_hash_contents = @flags.each_with_index.map do |flag, flag_index|
        "#{flag}: (#{@nil_handler.in_attribute_eval(@attribute)} & #{1 << flag_index}).positive?"
      end.join(', ')
      @model.class_eval EvalScripts.flag_settings(method_name, flag_hash_contents), __FILE__, __LINE__
    end

    def flag_getter_method
      @conflict_checker.check_instance_method!(@attribute)

      flag_array_contents = @flags.each_with_index.map do |flag, flag_index|
        "(#{@nil_handler.in_attribute_eval(@attribute)} & #{1 << flag_index}).positive? ? :#{flag} : nil"
      end.join(', ')
      @model.class_eval EvalScripts.flag_getter(@attribute, flag_array_contents), __FILE__, __LINE__
    end

    def flag_setter_method
      method_name = "#{@attribute}="

      @conflict_checker.check_instance_method!(method_name)

      @model.class_eval EvalScripts.flag_setter(method_name, @attribute), __FILE__, __LINE__
    end

    def class_flag_values_method
      @conflict_checker.check_class_method!(@attribute)

      @model.class_eval EvalScripts.class_flag_values(@attribute, @flags), __FILE__, __LINE__
    end
  end
end
