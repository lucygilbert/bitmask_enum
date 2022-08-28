# frozen_string_literal: true

module BitmaskEnum
  module EvalScripts
    class << self
      def flag_method(method_name, method_code)
        %(
          def #{method_name}  # def flag!
            #{method_code}    #   update!('attribs' => self['attribs'] ^ 1)
          end                 # end
        )
      end

      def flag_scope(scope_name, attribute, values_for_bitmask)
        %(
          scope :#{scope_name}, -> do                       # scope :flag_disabled, -> do
            where('#{attribute}' => #{values_for_bitmask})  #   where('attribs' => [0, 2, 4])
          end                                               # end
        )
      end

      def flag_settings(method_name, flag_hash_contents)
        %(
          def #{method_name}          # def attribs_settings
            { #{flag_hash_contents} } #   { flag: (self['attribs'] & 1).positive? }
          end                         # end
        )
      end

      def flag_getter(attribute, flag_array_contents)
        %(
          def #{attribute}                    # def attribs
            [#{flag_array_contents}].compact  #   [:flag]
          end                                 # end
        )
      end

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
