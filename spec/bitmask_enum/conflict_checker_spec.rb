# frozen_string_literal: true

RSpec.describe BitmaskEnum::ConflictChecker do
  context 'when methods conflict' do
    context 'when at the class level' do
      context 'with a method that exists in ActiveRecord' do
        let(:expected_error_type) { BitmaskEnum::BitmaskEnumMethodConflictError }
        let(:expected_error_message) do
          'BitmaskEnum method definition is conflicting: ' \
            'class method: create for enum: create in class: TestModel ' \
            'is already defined by: ActiveRecord'
        end

        it 'raises an error' do
          expect do
            Class.new(ActiveRecord::Base) do
              def self.name
                'TestModel'
              end

              bitmask_enum create: [:flag]
            end
          end.to raise_error(expected_error_type, expected_error_message)
        end
      end

      context 'with a method that exists in ActiveRecord::Relation' do
        let(:expected_error_type) { BitmaskEnum::BitmaskEnumMethodConflictError }
        let(:expected_error_message) do
          'BitmaskEnum method definition is conflicting: ' \
            'class method: values for enum: values in class: TestModel ' \
            'is already defined by: ActiveRecord::Relation'
        end

        it 'raises an error' do
          expect do
            Class.new(ActiveRecord::Base) do
              def self.name
                'TestModel'
              end

              bitmask_enum values: [:flag]
            end
          end.to raise_error(expected_error_type, expected_error_message)
        end
      end
    end

    context 'when at the instance level' do
      context 'with a method that exists in ActiveRecord' do
        let(:expected_error_type) { BitmaskEnum::BitmaskEnumMethodConflictError }
        let(:expected_error_message) do
          'BitmaskEnum method definition is conflicting: ' \
            'method: destroyed? for enum: attribs in class: TestModel ' \
            'is already defined by: ActiveRecord'
        end

        it 'raises an error' do
          expect do
            Class.new(ActiveRecord::Base) do
              def self.name
                'TestModel'
              end

              bitmask_enum attribs: [:destroyed]
            end
          end.to raise_error(expected_error_type, expected_error_message)
        end
      end

      context 'with a method that exists in another enum' do
        let(:expected_error_type) { BitmaskEnum::BitmaskEnumMethodConflictError }
        let(:expected_error_message) do
          'BitmaskEnum method definition is conflicting: ' \
            'method: flag? for enum: attribs in class: TestModel ' \
            'is already defined by: other_int'
        end

        it 'raises an error' do
          expect do
            Class.new(ActiveRecord::Base) do
              def self.name
                'TestModel'
              end

              bitmask_enum other_int: [:flag]
              bitmask_enum attribs: [:flag]
            end
          end.to raise_error(expected_error_type, expected_error_message)
        end
      end
    end
  end
end