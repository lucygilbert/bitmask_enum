# frozen_string_literal: true

require 'bitmask_enum/conflict_checker'

module BitmaskEnum
  class Attribute
    def initialize(model, attribute, flags, options, defined_enum_methods)
      @attribute = attribute
      @flags = flags
      @options = options
      @model = model
      @conflict_checker = ConflictChecker.new(model, attribute, defined_enum_methods)
    end

    def construct!
      flag_prefix, flag_suffix = fixes_from_options
      @flags.each_with_index do |flag, flag_index|
        per_flag_methods("#{flag_prefix}#{flag}#{flag_suffix}", flag_index)
      end

      flag_settings_hash_method
      enabled_flags_array_method

      class_flag_values_method
    end

    private

    def fixes_from_options
      prefix = @options[:flag_prefix] ? "#{@options[:flag_prefix]}_" : ''
      suffix = @options[:flag_suffix] ? "_#{@options[:flag_suffix]}" : ''

      [prefix, suffix]
    end

    def per_flag_methods(flag_label, flag_index)
      flag_check_method(flag_label, flag_index)
      flag_toggle_method(flag_label, flag_index)
      flag_on_method(flag_label, flag_index)
      flag_off_method(flag_label, flag_index)

      class_flag_enabled_scope(flag_label, flag_index)
      class_flag_disabled_scope(flag_label, flag_index)
    end

    def flag_check_method(flag_label, flag_index)
      flag_method("#{flag_label}?", "(self['#{@attribute}'] & #{1 << flag_index}).positive?")
    end

    def flag_toggle_method(flag_label, flag_index)
      flag_method("#{flag_label}!", "update!('#{@attribute}' => self['#{@attribute}'] ^ #{1 << flag_index})")
    end

    def flag_on_method(flag_label, flag_index)
      flag_method("enable_#{flag_label}!", "update!('#{@attribute}' => self['#{@attribute}'] | #{1 << flag_index})")
    end

    def flag_off_method(flag_label, flag_index)
      flag_method("disable_#{flag_label}!", "update!('#{@attribute}' => self['#{@attribute}'] & #{~(1 << flag_index)})")
    end

    def flag_method(method_name, method_code)
      @conflict_checker.check_instance_method!(method_name)
      @model.class_eval %(
        def #{method_name}  # def flag!
          #{method_code}    #   update!('attribs' => self['attribs'] ^ 1)
        end                 # end
      ), __FILE__, __LINE__ - 4
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

      @conflict_checker.check_class_method!(scope_name)

      @model.class_eval %(
        scope :#{scope_name}, -> do                       # scope :flag_disabled, -> do
          where('#{@attribute}' => #{values_for_bitmask}) #   where('attribs' => [0, 2, 4])
        end                                               # end
      ), __FILE__, __LINE__ - 4
    end

    def flag_settings_hash_method
      method_name = "#{@attribute}_settings"
      @conflict_checker.check_instance_method!(method_name)
      flag_hash_contents = @flags.each_with_index.map do |flag, flag_index|
        "#{flag}: (self['#{@attribute}'] & #{1 << flag_index}).positive?"
      end.join(', ')
      @model.class_eval %(
        def #{method_name}          # def attribs_settings
          { #{flag_hash_contents} } #   { flag: (self['attribs'] & 1).positive? }
        end                         # end
      ), __FILE__, __LINE__ - 4
    end

    def enabled_flags_array_method
      @conflict_checker.check_instance_method!(@attribute)
      flag_array_contents = @flags.each_with_index.map do |flag, flag_index|
        "(self['#{@attribute}'] & #{1 << flag_index}).positive? ? :#{flag} : nil"
      end.join(', ')
      @model.class_eval %(
        def #{@attribute}                   # def attribs
          [#{flag_array_contents}].compact  #   [:flag]
        end                                 # end
      ), __FILE__, __LINE__ - 4
    end

    def class_flag_values_method
      @conflict_checker.check_class_method!(@attribute)
      @model.class_eval %(
        def self.#{@attribute}  # def self.attribs
          #{@flags}             #   [:flag]
        end                     # end
      ), __FILE__, __LINE__ - 4
    end
  end
end
