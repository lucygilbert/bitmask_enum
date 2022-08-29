# frozen_string_literal: true

require 'fixtures/attribute'

RSpec.describe BitmaskEnum::NilHandler do
  include Fixtures::Attribute

  shared_examples 'include or default nil handling' do
    after do
      ActiveRecord::Base.connection.execute("DELETE FROM #{table_name}")
    end

    FLAGS.each_with_index do |flag, flag_index|
      describe "##{flag}?" do
        context 'when the attribute is nil' do
          subject(:instance) { model.create!(attribs: nil) }

          it 'returns false' do
            expect(instance.public_send("#{flag}?")).to be false
          end
        end
      end

      describe "##{flag}!" do
        context 'when the attribute is nil' do
          subject(:instance) { model.create!(attribs: nil) }

          it 'enables the flag' do
            instance.public_send("#{flag}!")

            expect(instance.public_send("#{flag}?")).to be true
          end
        end
      end

      describe "#enable_#{flag}!" do
        context 'when the attribute is nil' do
          subject(:instance) { model.create!(attribs: nil) }

          it 'enables the flag' do
            instance.public_send("enable_#{flag}!")

            expect(instance.public_send("#{flag}?")).to be true
          end
        end
      end

      describe "#disable_#{flag}!" do
        context 'when the attribute is nil' do
          subject(:instance) { model.create!(attribs: nil) }

          it 'sets the attribute to 0' do
            instance.public_send("disable_#{flag}!")

            expect(instance.attribs).to eq []
          end
        end
      end

      describe 'scopes with nil records' do
        let(:instances) do
          [
            model.create!(attribs: all_enabled_attribs.to_i(2)),
            model.create!(attribs: all_enabled_but_one_attribs(flag_index).to_i(2)),
            model.create!(attribs: all_disabled_but_one_attribs(flag_index).to_i(2)),
            model.create!(attribs: all_disabled_attribs.to_i(2)),
            model.create!(attribs: one_set_others_mixed_attribs(flag_index).to_i(2)),
            model.create!(attribs: one_set_others_mixed_attribs(flag_index, enabled: false).to_i(2)),
            model.create!(attribs: nil)
          ]
        end

        describe ".#{flag}_enabled" do
          it 'returns all records for which the flag is enabled' do
            expect(model.public_send("#{flag}_enabled")).to contain_exactly(
              instances[0], instances[2], instances[4]
            )
          end
        end

        describe ".#{flag}_disabled" do
          it 'returns all records for which the flag is disabled' do
            expect(model.public_send("#{flag}_disabled")).to contain_exactly(
              instances[1], instances[3], instances[5], instances[6]
            )
          end
        end
      end
    end

    describe '#attribs_settings' do
      context 'when the attribute is nil' do
        subject(:instance) { model.create!(attribs: nil) }

        it 'returns a hash with all flags set to false' do
          expect(instance.attribs_settings).to eq(flag: false, flag2: false, flag3: false)
        end
      end
    end

    describe '#attribs' do
      context 'when the attribute is nil' do
        subject(:instance) { model.create!(attribs: nil) }

        it 'returns an empty array' do
          expect(instance.attribs).to eq []
        end
      end
    end
  end

  context 'with default nil handling' do
    it_behaves_like 'include or default nil handling' do
      let(:model) { TestModel }
      let(:table_name) { 'test_models' }
    end
  end

  context 'with :include nil handling' do
    it_behaves_like 'include or default nil handling' do
      let(:model) { IncludeNilHandlerTestModel }
      let(:table_name) { 'include_nil_handler_test_models' }
    end
  end

  context 'with an unrecognized setting for nil handling' do
    let(:expected_error_type) { BitmaskEnum::BitmaskEnumInvalidError }
    let(:expected_error_message) { 'BitmaskEnum definition is invalid: bork is not a valid nil handling option' }

    it 'raises an error' do
      expect do
        Class.new(ActiveRecord::Base) do
          bitmask_enum attribs: [:flag], nil_handling: :bork
        end
      end.to raise_error(expected_error_type, expected_error_message)
    end
  end
end
