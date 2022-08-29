# frozen_string_literal: true

module BitmaskEnum
  # Code strings to be templated and evaled to create methods
  # @api private
  module EvalScripts
    class << self
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

      # Code for methods scoping by flag: `.flag_enabled`, `.flag_disabled`
      # @param scope_name [String] Name of the scope
      # @param attribute [String] Name of the attribute
      # @param values_for_bitmask [Array] Array of integers for which the flag would be enabled or disabled
      # @return [String] Code string to be evaled
      def flag_scope(scope_name, attribute, values_for_bitmask)
        %(
          scope :#{scope_name}, -> do                       # scope :flag_disabled, -> do
            where('#{attribute}' => #{values_for_bitmask})  #   where('attribs' => [0, 2, 4])
          end                                               # end
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
          def #{method_name}(value)                                  # def attribs=(value)
            if value.is_a?(Integer)                                  #   if value.is_a?(Integer)
              super                                                  #     super
            else                                                     #   else
              super(Array(value).reduce(0) do |acc, x|               #     super(Array(value).reduce(0) do |acc, x|
                acc |                                                #       acc |
                  (1 << (self.class.#{attribute}.index(x) || 0))     #         (1 << (self.class.attribs.index(x) || 0))
              end)                                                   #     end)
            end                                                      #   end
          end                                                        # end
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
