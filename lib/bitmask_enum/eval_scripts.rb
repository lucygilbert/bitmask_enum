# frozen_string_literal: true

module BitmaskEnum
  # Code strings to be templated and evaled to create methods
  # @api private
  module EvalScripts
    class << self
      # Code for validation method checking attribute is within valid values
      # @param attribute [String] Name of the attribute
      # @param flags_size [Integer] Number of defined flags
      # @return [String] Code string to be evaled
      def attribute_validation(attribute, flags_size)
        %(
          validates(                                          # validates(
            :#{attribute},                                    #   :attribs,
            numericality: { less_than: (1 << #{flags_size}) } #   numericality: { less_than: (1 << 3) }
          )                                                   # )
        )
      end

      # Code for methods checking and setting flags: `#flag?`, `#flag!`, `#enable_flag!`, `#disable_flag!`
      # @param method_name [String] Name of the method
      # @param method_code [String] Code contents of the method
      # @return [String] Code string to be evaled
      def flag_method(method_name, method_code)
        %(
          def #{method_name}  # def flag!
            #{method_code}    #   update!('attribs' => self['attribs'] ^ 1)
          end                 # end
        )
      end

      # Code for methods dynamically testing flags on a model: `#any_attribs_enabled?`, `#all_attribs_disabled?`
      # The methods will take a symbol representing a flag or an array of symbols representing flags
      # @param method_name [String] Name of the method
      # @param attribute [String] Name of the attribute
      # @param test_method [String] Name of the method used to test the provided flags against the model
      # @param boolean [Boolean] Boolean to test flags against
      # @return [String] Code string to be evaled
      def flag_test_method(method_name, attribute, test_method, boolean)
        bool_text = boolean == true ? 'true' : 'false'

        %(
          def #{method_name}(flags)                              # def any_attribs_enabled?(flags)
            Array(flags).#{test_method} do |flag|                #   Array(flags).any? do |flag|
              if self.class.#{attribute}.index(flag.to_sym).nil? #     if self.class.attribs.index(flag.to_sym).nil?
                raise(                                           #       raise(
                  ArgumentError,                                 #         ArgumentError,
                  "Invalid flag \#{flag} for #{attribute}"       #         "Invalid flag \#{flag} for attribs"
                )                                                #       )
              end                                                #     end
              #{attribute}_settings[flag.to_sym] == #{bool_text} #     attribs_settings[flag.to_sym] == true
            end                                                  #   end
          end                                                    # end
        )
      end

      # Code for methods scoping by flag: `.flag_enabled`, `.flag_disabled`
      # @param scope_name [String] Name of the scope
      # @param attribute [String] Name of the attribute
      # @param values_for_bitmask [Array] Array of integers for which the flag would be enabled/disabled
      # @return [String] Code string to be evaled
      def flag_scope(scope_name, attribute, values_for_bitmask)
        %(
          scope :#{scope_name}, -> do                       # scope :flag_disabled, -> do
            where('#{attribute}' => #{values_for_bitmask})  #   where('attribs' => [0, 2, 4])
          end                                               # end
        )
      end

      # Code for methods dynamically scoping by flags: `.attribs_enabled`, `.attribs_disabled`
      # @param scope_name [String] Name of the scope
      # @param attribute [String] Name of the attribute
      # @param flags_and_values [Array] Array of arrays, first being the flag, second being the enum values for the flag
      # @param bitwise_operator [String] Bitwise operator used to combine the enum value arrays
      # @return [String] Code string to be evaled
      def dynamic_scope(scope_name, attribute, flags_and_values, bitwise_operator)
        %(
scope :#{scope_name}, ->(flags) do                             # scope :attribs_disabled, ->(flags) do
  enum_values = {                                              #   enum_values = {
    #{flags_and_values.map { |f, v| "#{f}: #{v}" }.join(', ')} #     flag: [1,3], flag2: [2]
  }                                                            #   }
                                                               #
  where('#{attribute}' => Array(flags).map do |flag|           #   where('attribs' => Array(flags).map do |flag|
    flag_values = enum_values[flag.to_sym]                     #     flag_values = enum_values[flag.to_sym]
    if flag_values.nil?                                        #     if flag_index.nil?
      raise(                                                   #       raise(
        ArgumentError,                                         #         ArgumentError,
        "Invalid flag \#{flag} for #{attribute}"               #         "Invalid flag \#{flag} for attribs"
      )                                                        #       )
    end                                                        #     end
    flag_values                                                #     flag_values
  end.reduce(&:#{bitwise_operator}))                           #   end.map(&:|))
end                                                            # end
        )
      end

      # Code for method returning hash of flags with their boolean setting: `#attribs_settings`
      # @param method_name [String] Name of the method
      # @param flag_hash_contents [String] Contents of the hash which provides the flag settings
      # @return [String] The code string to be evaled
      def flag_settings(method_name, flag_hash_contents)
        %(
          def #{method_name}          # def attribs_settings
            { #{flag_hash_contents} } #   { flag: (self['attribs'] & 1).positive? }
          end                         # end
        )
      end

      # Code for attribute getter method: `#attribs`
      # The return value of the method will be an array of symbols representing the enabled flags
      # @param attribute [String] Name of the attribute
      # @param flag_array_contents [String] Contents of the array which provides the enabled flags
      # @return [String] The code string to be evaled
      def flag_getter(attribute, flag_array_contents)
        %(
          def #{attribute}                    # def attribs
            [#{flag_array_contents}].compact  #   [((self['attribs'] || 0) & 1).positive? ? :flag : nil].compact
          end                                 # end
        )
      end

      # Code for attribute setter method: `#attribs=`
      # The method will take an integer, a symbol representing a flag or an array of symbols representing flags
      # @param method_name [String] Name of the method (the attribute name with an =)
      # @param attribute [String] Name of the attribute
      # @return [String] The code string to be evaled
      def flag_setter(method_name, attribute)
        %(
def #{method_name}(value)                                     # def attribs=(value)
  if value.is_a?(Integer)                                     #   if value.is_a?(Integer)
    super                                                     #     super
  else                                                        #   else
    super(Array(value).reduce(0) do |acc, flag|               #     super(Array(value).reduce(0) do |acc, x|
      flag_index = self.class.#{attribute}.index(flag.to_sym) #       flag_index = self.class.attribs.index(flag.to_sym)
      if flag_index.nil?                                      #       if flag_index.nil?
        raise(                                                #         raise(
          ArgumentError,                                      #           ArgumentError,
          "Invalid flag \#{flag} for #{attribute}"            #           "Invalid flag \#{flag} for attribs"
        )                                                     #         )
      end                                                     #       end
      acc | (1 << flag_index)                                 #       acc | (1 << flag_index)
    end)                                                      #     end)
  end                                                         #   end
end                                                           # end
        )
      end

      # Code for class attribute values method: `#attribs=`
      # The return value of the method will be an array of symbols representing all defined flags
      # @param attribute [String] Name of the attribute
      # @param flags [String] Array of symbols representing all defined flags
      # @return [String] The code string to be evaled
      def class_flag_values(attribute, flags)
        %(
          def self.#{attribute}  # def self.attribs
            #{flags}             #   [:flag]
          end                    # end
        )
      end
    end
  end
end
