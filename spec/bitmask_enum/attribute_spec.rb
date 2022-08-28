# frozen_string_literal: true

require 'fixtures/attribute'

RSpec.describe BitmaskEnum::Attribute do
  include Fixtures::Attribute

  def expect_other_flags_unchanged(method_name, flag, instance)
    initial_values = current_flag_settings_excluding(flag, instance)

    instance.public_send(method_name)

    post_action_values = current_flag_settings_excluding(flag, instance)

    expect(post_action_values).to eq(initial_values)
  end

  def current_flag_settings_excluding(flag, instance)
    (FLAGS - [flag]).map do |other_flag|
      instance.public_send("#{other_flag}?")
    end
  end

  after do
    ActiveRecord::Base.connection.execute('DELETE FROM test_models')
  end

  FLAGS.each_with_index do |flag, flag_index|
    describe "##{flag}?" do
      shared_examples 'checking the flag' do
        context 'when the flag is enabled' do
          subject(:instance) { TestModel.create!(attribs: enabled_attribs.to_i(2)) }

          it 'returns true' do
            expect(instance.public_send("#{flag}?")).to be true
          end

          it 'is idempotent' do
            expect(3.times.map { instance.public_send("#{flag}?") }).to eq [true, true, true]
          end

          it 'does not affect other flags' do
            expect_other_flags_unchanged("#{flag}?", flag, instance)
          end
        end

        context 'when the flag is disabled' do
          subject(:instance) { TestModel.create!(attribs: disabled_attribs.to_i(2)) }

          it 'returns false' do
            expect(instance.public_send("#{flag}?")).to be false
          end

          it 'is idempotent' do
            expect(3.times.map { instance.public_send("#{flag}?") }).to eq [false, false, false]
          end

          it 'does not affect other flags' do
            expect_other_flags_unchanged("#{flag}?", flag, instance)
          end
        end
      end

      context 'when all other flags are enabled' do
        it_behaves_like 'checking the flag' do
          let(:enabled_attribs) { all_enabled_attribs }
          let(:disabled_attribs) { all_enabled_but_one_attribs(flag_index) }
        end
      end

      context 'when all other flags are disabled' do
        it_behaves_like 'checking the flag' do
          let(:enabled_attribs) { all_disabled_but_one_attribs(flag_index) }
          let(:disabled_attribs) { all_disabled_attribs }
        end
      end

      context 'when other flags have a mix of settings' do
        it_behaves_like 'checking the flag' do
          let(:enabled_attribs) { one_set_others_mixed_attribs(flag_index) }
          let(:disabled_attribs) { one_set_others_mixed_attribs(flag_index, enabled: false) }
        end
      end
    end

    describe "##{flag}!" do
      shared_examples 'toggling the flag' do
        context 'when the flag is enabled' do
          subject(:instance) { TestModel.create!(attribs: enabled_attribs.to_i(2)) }

          it 'disables the flag' do
            instance.public_send("#{flag}!")

            expect(instance.public_send("#{flag}?")).to be false
          end

          it 'does not affect other flags' do
            expect_other_flags_unchanged("#{flag}!", flag, instance)
          end
        end

        context 'when the flag is disabled' do
          subject(:instance) { TestModel.create!(attribs: disabled_attribs.to_i(2)) }

          it 'enables the flag' do
            instance.public_send("#{flag}!")

            expect(instance.public_send("#{flag}?")).to be true
          end

          it 'does not affect other flags' do
            expect_other_flags_unchanged("#{flag}!", flag, instance)
          end
        end
      end

      context 'when all other flags are enabled' do
        it_behaves_like 'toggling the flag' do
          let(:enabled_attribs) { all_enabled_attribs }
          let(:disabled_attribs) { all_enabled_but_one_attribs(flag_index) }
        end
      end

      context 'when all other flags are disabled' do
        it_behaves_like 'toggling the flag' do
          let(:enabled_attribs) { all_disabled_but_one_attribs(flag_index) }
          let(:disabled_attribs) { all_disabled_attribs }
        end
      end

      context 'when other flags have a mix of settings' do
        it_behaves_like 'toggling the flag' do
          let(:enabled_attribs) { one_set_others_mixed_attribs(flag_index) }
          let(:disabled_attribs) { one_set_others_mixed_attribs(flag_index, enabled: false) }
        end
      end
    end

    describe "#enable_#{flag}!" do
      shared_examples 'enabling the flag' do
        context 'when the flag is enabled' do
          subject(:instance) { TestModel.create!(attribs: enabled_attribs.to_i(2)) }

          it 'does nothing' do
            instance.public_send("enable_#{flag}!")

            expect(instance.public_send("#{flag}?")).to be true
          end

          it 'does not affect other flags' do
            expect_other_flags_unchanged("enable_#{flag}!", flag, instance)
          end
        end

        context 'when the flag is disabled' do
          subject(:instance) { TestModel.create!(attribs: disabled_attribs.to_i(2)) }

          it 'enables the flag' do
            instance.public_send("enable_#{flag}!")

            expect(instance.public_send("#{flag}?")).to be true
          end

          it 'does not affect other flags' do
            expect_other_flags_unchanged("enable_#{flag}!", flag, instance)
          end
        end
      end

      context 'when all other flags are enabled' do
        it_behaves_like 'enabling the flag' do
          let(:enabled_attribs) { all_enabled_attribs }
          let(:disabled_attribs) { all_enabled_but_one_attribs(flag_index) }
        end
      end

      context 'when all other flags are disabled' do
        it_behaves_like 'enabling the flag' do
          let(:enabled_attribs) { all_disabled_but_one_attribs(flag_index) }
          let(:disabled_attribs) { all_disabled_attribs }
        end
      end

      context 'when other flags have a mix of settings' do
        it_behaves_like 'enabling the flag' do
          let(:enabled_attribs) { one_set_others_mixed_attribs(flag_index) }
          let(:disabled_attribs) { one_set_others_mixed_attribs(flag_index, enabled: false) }
        end
      end
    end

    describe "#disable_#{flag}!" do
      shared_examples 'disabling the flag' do
        context 'when the flag is enabled' do
          subject(:instance) { TestModel.create!(attribs: enabled_attribs.to_i(2)) }

          it 'disables the flag' do
            instance.public_send("disable_#{flag}!")

            expect(instance.public_send("#{flag}?")).to be false
          end

          it 'does not affect other flags' do
            expect_other_flags_unchanged("disable_#{flag}!", flag, instance)
          end
        end

        context 'when the flag is disabled' do
          subject(:instance) { TestModel.create!(attribs: disabled_attribs.to_i(2)) }

          it 'does nothing' do
            instance.public_send("disable_#{flag}!")

            expect(instance.public_send("#{flag}?")).to be false
          end

          it 'does not affect other flags' do
            expect_other_flags_unchanged("disable_#{flag}!", flag, instance)
          end
        end
      end

      context 'when all other flags are enabled' do
        it_behaves_like 'disabling the flag' do
          let(:enabled_attribs) { all_enabled_attribs }
          let(:disabled_attribs) { all_enabled_but_one_attribs(flag_index) }
        end
      end

      context 'when all other flags are disabled' do
        it_behaves_like 'disabling the flag' do
          let(:enabled_attribs) { all_disabled_but_one_attribs(flag_index) }
          let(:disabled_attribs) { all_disabled_attribs }
        end
      end

      context 'when other flags have a mix of settings' do
        it_behaves_like 'disabling the flag' do
          let(:enabled_attribs) { one_set_others_mixed_attribs(flag_index) }
          let(:disabled_attribs) { one_set_others_mixed_attribs(flag_index, enabled: false) }
        end
      end
    end

    describe 'scopes' do
      let(:instances) do
        [
          TestModel.create!(attribs: all_enabled_attribs.to_i(2)),
          TestModel.create!(attribs: all_enabled_but_one_attribs(flag_index).to_i(2)),
          TestModel.create!(attribs: all_disabled_but_one_attribs(flag_index).to_i(2)),
          TestModel.create!(attribs: all_disabled_attribs.to_i(2)),
          TestModel.create!(attribs: one_set_others_mixed_attribs(flag_index).to_i(2)),
          TestModel.create!(attribs: one_set_others_mixed_attribs(flag_index, enabled: false).to_i(2))
        ]
      end

      describe ".#{flag}_enabled" do
        it 'returns all records for which the flag is enabled' do
          expect(TestModel.public_send("#{flag}_enabled")).to contain_exactly(
            instances[0], instances[2], instances[4]
          )
        end

        it 'does not change any record' do
          initial_values = TestModel.pluck(:attribs)
          TestModel.public_send("#{flag}_enabled")
          post_action_values = TestModel.pluck(:attribs)

          expect(post_action_values).to eq(initial_values)
        end
      end

      describe ".#{flag}_disabled" do
        it 'returns all records for which the flag is disabled' do
          expect(TestModel.public_send("#{flag}_disabled")).to contain_exactly(
            instances[1], instances[3], instances[5]
          )
        end

        it 'does not change any record' do
          initial_values = TestModel.pluck(:attribs)
          TestModel.public_send("#{flag}_disabled")
          post_action_values = TestModel.pluck(:attribs)

          expect(post_action_values).to eq(initial_values)
        end
      end
    end
  end

  describe '#attribs_settings' do
    context 'when all flags are enabled' do
      subject(:instance) { TestModel.create!(attribs: all_enabled_attribs.to_i(2)) }

      it 'returns a hash with all flags set to true' do
        expect(instance.attribs_settings).to eq(flag: true, flag2: true, flag3: true)
      end
    end

    context 'when all flags are disabled' do
      subject(:instance) { TestModel.create!(attribs: all_disabled_attribs.to_i(2)) }

      it 'returns a hash with all flags set to false' do
        expect(instance.attribs_settings).to eq(flag: false, flag2: false, flag3: false)
      end
    end

    context 'when flags have a mix of settings' do
      subject(:instance) { TestModel.create!(attribs: one_set_others_mixed_attribs(2).to_i(2)) }

      it 'returns a hash with flags set to the correct values' do
        expect(instance.attribs_settings).to eq(flag: true, flag2: false, flag3: true)
      end
    end
  end

  describe '#attribs' do
    context 'when all flags are enabled' do
      subject(:instance) { TestModel.create!(attribs: all_enabled_attribs.to_i(2)) }

      it 'returns an array of all flags' do
        expect(instance.attribs).to eq %i[flag flag2 flag3]
      end
    end

    context 'when all flags are disabled' do
      subject(:instance) { TestModel.create!(attribs: all_disabled_attribs.to_i(2)) }

      it 'returns an empty array' do
        expect(instance.attribs).to eq []
      end
    end

    context 'when flags have a mix of settings' do
      subject(:instance) { TestModel.create!(attribs: one_set_others_mixed_attribs(2).to_i(2)) }

      it 'returns an array of only the enabled flags' do
        expect(instance.attribs).to eq %i[flag flag3]
      end
    end
  end

  describe '.attribs' do
    it 'returns all defined flags' do
      expect(TestModel.attribs).to eq FLAGS
    end
  end
end
