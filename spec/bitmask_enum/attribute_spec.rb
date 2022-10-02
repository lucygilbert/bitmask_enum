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

  shared_examples 'sets methods correctly' do
    after do
      ActiveRecord::Base.connection.execute("DELETE FROM #{table_name}")
    end

    FLAGS.each_with_index do |flag, flag_index|
      describe "##{flag}?" do
        shared_examples 'checking the flag' do
          context 'when the flag is enabled' do
            subject(:instance) { model.create!(attribs: enabled_attribs.to_i(2)) }

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
            subject(:instance) { model.create!(attribs: disabled_attribs.to_i(2)) }

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
            subject(:instance) { model.create!(attribs: enabled_attribs.to_i(2)) }

            it 'disables the flag' do
              instance.public_send("#{flag}!")

              expect(instance.public_send("#{flag}?")).to be false
            end

            it 'does not affect other flags' do
              expect_other_flags_unchanged("#{flag}!", flag, instance)
            end
          end

          context 'when the flag is disabled' do
            subject(:instance) { model.create!(attribs: disabled_attribs.to_i(2)) }

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
            subject(:instance) { model.create!(attribs: enabled_attribs.to_i(2)) }

            it 'does nothing' do
              instance.public_send("enable_#{flag}!")

              expect(instance.public_send("#{flag}?")).to be true
            end

            it 'does not affect other flags' do
              expect_other_flags_unchanged("enable_#{flag}!", flag, instance)
            end
          end

          context 'when the flag is disabled' do
            subject(:instance) { model.create!(attribs: disabled_attribs.to_i(2)) }

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
            subject(:instance) { model.create!(attribs: enabled_attribs.to_i(2)) }

            it 'disables the flag' do
              instance.public_send("disable_#{flag}!")

              expect(instance.public_send("#{flag}?")).to be false
            end

            it 'does not affect other flags' do
              expect_other_flags_unchanged("disable_#{flag}!", flag, instance)
            end
          end

          context 'when the flag is disabled' do
            subject(:instance) { model.create!(attribs: disabled_attribs.to_i(2)) }

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
            model.create!(attribs: all_enabled_attribs.to_i(2)),
            model.create!(attribs: all_enabled_but_one_attribs(flag_index).to_i(2)),
            model.create!(attribs: all_disabled_but_one_attribs(flag_index).to_i(2)),
            model.create!(attribs: all_disabled_attribs.to_i(2)),
            model.create!(attribs: one_set_others_mixed_attribs(flag_index).to_i(2)),
            model.create!(attribs: one_set_others_mixed_attribs(flag_index, enabled: false).to_i(2))
          ]
        end

        describe ".#{flag}_enabled" do
          it 'returns all records for which the flag is enabled' do
            expect(model.public_send("#{flag}_enabled")).to contain_exactly(
              instances[0], instances[2], instances[4]
            )
          end

          it 'does not change any record' do
            initial_values = model.pluck(:attribs)
            model.public_send("#{flag}_enabled")
            post_action_values = model.pluck(:attribs)

            expect(post_action_values).to eq(initial_values)
          end
        end

        describe ".#{flag}_disabled" do
          it 'returns all records for which the flag is disabled' do
            expect(model.public_send("#{flag}_disabled")).to contain_exactly(
              instances[1], instances[3], instances[5]
            )
          end

          it 'does not change any record' do
            initial_values = model.pluck(:attribs)
            model.public_send("#{flag}_disabled")
            post_action_values = model.pluck(:attribs)

            expect(post_action_values).to eq(initial_values)
          end
        end
      end
    end

    describe '#any_attribs_enabled?' do
      shared_examples 'checks the flags correctly' do
        context 'when all flags are enabled' do
          subject(:instance) { model.create!(attribs: all_enabled_attribs.to_i(2)) }

          it 'returns true' do
            expect(instance.any_attribs_enabled?(flags)).to be(true)
          end
        end

        context 'when some flags including some provided ones are enabled' do
          subject(:instance) { model.create!(attribs: all_enabled_but_one_attribs(0).to_i(2)) }

          it 'returns true' do
            expect(instance.any_attribs_enabled?(flags)).to be(true)
          end
        end

        context 'when some flags not including the provided ones are enabled' do
          subject(:instance) { model.create!(attribs: all_disabled_but_one_attribs(1).to_i(2)) }

          it 'returns true' do
            expect(instance.any_attribs_enabled?(flags)).to be(false)
          end
        end

        context 'when all flags are disabled' do
          subject(:instance) { model.create!(attribs: all_disabled_attribs.to_i(2)) }

          it 'returns false' do
            expect(instance.any_attribs_enabled?(flags)).to be(false)
          end
        end
      end

      context 'with one string flag' do
        it_behaves_like 'checks the flags correctly' do
          let(:flags) { 'flag3' }
        end
      end

      context 'with multiple string flags' do
        it_behaves_like 'checks the flags correctly' do
          let(:flags) { %w[flag flag3] }
        end
      end

      context 'with one symbol flag' do
        it_behaves_like 'checks the flags correctly' do
          let(:flags) { :flag3 }
        end
      end

      context 'with multiple symbol flags' do
        it_behaves_like 'checks the flags correctly' do
          let(:flags) { %i[flag flag3] }
        end
      end

      context 'with an invalid symbol flag' do
        subject(:instance) { model.create!(attribs: all_disabled_attribs.to_i(2)) }

        it 'raises an error' do
          expect { instance.any_attribs_enabled?(:invalid) }.to raise_error(
            ArgumentError, 'Invalid flag invalid for attribs'
          )
        end
      end

      context 'with an invalid string flag' do
        subject(:instance) { model.create!(attribs: all_disabled_attribs.to_i(2)) }

        it 'raises an error' do
          expect { instance.any_attribs_enabled?('invalid') }.to raise_error(
            ArgumentError, 'Invalid flag invalid for attribs'
          )
        end
      end
    end

    describe '#any_attribs_disabled?' do
      shared_examples 'checks the flags correctly' do
        context 'when all flags are enabled' do
          subject(:instance) { model.create!(attribs: all_enabled_attribs.to_i(2)) }

          it 'returns false' do
            expect(instance.any_attribs_disabled?(flags)).to be(false)
          end
        end

        context 'when some flags including some provided ones are disabled' do
          subject(:instance) { model.create!(attribs: all_disabled_but_one_attribs(0).to_i(2)) }

          it 'returns true' do
            expect(instance.any_attribs_disabled?(flags)).to be(true)
          end
        end

        context 'when some flags not including the provided ones are disabled' do
          subject(:instance) { model.create!(attribs: all_enabled_but_one_attribs(1).to_i(2)) }

          it 'returns true' do
            expect(instance.any_attribs_disabled?(flags)).to be(false)
          end
        end

        context 'when all flags are disabled' do
          subject(:instance) { model.create!(attribs: all_disabled_attribs.to_i(2)) }

          it 'returns false' do
            expect(instance.any_attribs_disabled?(flags)).to be(true)
          end
        end
      end

      context 'with one string flag' do
        it_behaves_like 'checks the flags correctly' do
          let(:flags) { 'flag3' }
        end
      end

      context 'with multiple string flags' do
        it_behaves_like 'checks the flags correctly' do
          let(:flags) { %w[flag flag3] }
        end
      end

      context 'with one symbol flag' do
        it_behaves_like 'checks the flags correctly' do
          let(:flags) { :flag3 }
        end
      end

      context 'with multiple symbol flags' do
        it_behaves_like 'checks the flags correctly' do
          let(:flags) { %i[flag flag3] }
        end
      end

      context 'with an invalid symbol flag' do
        subject(:instance) { model.create!(attribs: all_disabled_attribs.to_i(2)) }

        it 'raises an error' do
          expect { instance.any_attribs_disabled?(:invalid) }.to raise_error(
            ArgumentError, 'Invalid flag invalid for attribs'
          )
        end
      end

      context 'with an invalid string flag' do
        subject(:instance) { model.create!(attribs: all_disabled_attribs.to_i(2)) }

        it 'raises an error' do
          expect { instance.any_attribs_disabled?('invalid') }.to raise_error(
            ArgumentError, 'Invalid flag invalid for attribs'
          )
        end
      end
    end

    describe '#attribs_settings' do
      context 'when all flags are enabled' do
        subject(:instance) { model.create!(attribs: all_enabled_attribs.to_i(2)) }

        it 'returns a hash with all flags set to true' do
          expect(instance.attribs_settings).to eq(flag: true, flag2: true, flag3: true)
        end
      end

      context 'when all flags are disabled' do
        subject(:instance) { model.create!(attribs: all_disabled_attribs.to_i(2)) }

        it 'returns a hash with all flags set to false' do
          expect(instance.attribs_settings).to eq(flag: false, flag2: false, flag3: false)
        end
      end

      context 'when flags have a mix of settings' do
        subject(:instance) { model.create!(attribs: one_set_others_mixed_attribs(2).to_i(2)) }

        it 'returns a hash with flags set to the correct values' do
          expect(instance.attribs_settings).to eq(flag: true, flag2: false, flag3: true)
        end
      end
    end

    describe '#attribs' do
      context 'when all flags are enabled' do
        subject(:instance) { model.create!(attribs: all_enabled_attribs.to_i(2)) }

        it 'returns an array of all flags' do
          expect(instance.attribs).to eq %i[flag flag2 flag3]
        end
      end

      context 'when all flags are disabled' do
        subject(:instance) { model.create!(attribs: all_disabled_attribs.to_i(2)) }

        it 'returns an empty array' do
          expect(instance.attribs).to eq []
        end
      end

      context 'when flags have a mix of settings' do
        subject(:instance) { model.create!(attribs: one_set_others_mixed_attribs(2).to_i(2)) }

        it 'returns an array of only the enabled flags' do
          expect(instance.attribs).to eq %i[flag flag3]
        end
      end
    end

    describe '.no_attribs_enabled' do
      let(:instances) do
        [
          model.create!(attribs: all_enabled_attribs.to_i(2)),
          model.create!(attribs: all_enabled_but_one_attribs(1).to_i(2)),
          model.create!(attribs: all_disabled_but_one_attribs(1).to_i(2)),
          model.create!(attribs: all_disabled_attribs.to_i(2)),
          model.create!(attribs: one_set_others_mixed_attribs(1).to_i(2)),
          model.create!(attribs: one_set_others_mixed_attribs(1, enabled: false).to_i(2)),
          model.create!(attribs: all_disabled_attribs.to_i(2))
        ]
      end

      let(:expected_instances) { [instances[3], instances[6]] }

      it 'returns all records with no flags set' do
        expect(model.no_attribs_enabled).to match_array(
          expected_instances
        )
      end

      it 'does not change any record' do
        initial_values = model.pluck(:attribs)
        model.no_attribs_enabled
        post_action_values = model.pluck(:attribs)

        expect(post_action_values).to eq(initial_values)
      end
    end

    describe 'dynamic scopes' do
      shared_examples 'scopes correctly' do
        it 'returns all records for the flags setting' do
          expect(model.public_send(scope_name, flags)).to match_array(
            expected_instances
          )
        end

        it 'does not change any record' do
          initial_values = model.pluck(:attribs)
          model.public_send(scope_name, flags)
          post_action_values = model.pluck(:attribs)

          expect(post_action_values).to eq(initial_values)
        end
      end

      let(:instances) do
        [
          model.create!(attribs: all_enabled_attribs.to_i(2)),
          model.create!(attribs: all_enabled_but_one_attribs(1).to_i(2)),
          model.create!(attribs: all_disabled_but_one_attribs(1).to_i(2)),
          model.create!(attribs: all_disabled_attribs.to_i(2)),
          model.create!(attribs: one_set_others_mixed_attribs(1).to_i(2)),
          model.create!(attribs: one_set_others_mixed_attribs(1, enabled: false).to_i(2))
        ]
      end

      describe '.any_attribs_enabled' do
        let(:scope_name) { 'any_attribs_enabled' }

        context 'with one symbol flag' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { :flag2 }
            let(:expected_instances) { [instances[0], instances[2], instances[4]] }
          end
        end

        context 'with multiple symbol flags' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { %i[flag2 flag3] }
            let(:expected_instances) { [instances[0], instances[1], instances[2], instances[4], instances[5]] }
          end
        end

        context 'with one string flag' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { 'flag2' }
            let(:expected_instances) { [instances[0], instances[2], instances[4]] }
          end
        end

        context 'with multiple string flags' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { %w[flag2 flag3] }
            let(:expected_instances) { [instances[0], instances[1], instances[2], instances[4], instances[5]] }
          end
        end

        context 'with an invalid symbol flag' do
          it 'raises an error' do
            expect { model.public_send(scope_name, :invalid) }.to raise_error(
              ArgumentError, 'Invalid flag invalid for attribs'
            )
          end
        end

        context 'with an invalid string flag' do
          it 'raises an error' do
            expect { model.public_send(scope_name, 'invalid') }.to raise_error(
              ArgumentError, 'Invalid flag invalid for attribs'
            )
          end
        end
      end

      describe '.any_attribs_disabled' do
        let(:scope_name) { 'any_attribs_disabled' }

        context 'with one symbol flag' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { :flag2 }
            let(:expected_instances) { [instances[1], instances[3], instances[5]] }
          end
        end

        context 'with multiple symbol flags' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { %i[flag2 flag3] }
            let(:expected_instances) { [instances[1], instances[2], instances[3], instances[5]] }
          end
        end

        context 'with one string flag' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { 'flag2' }
            let(:expected_instances) { [instances[1], instances[3], instances[5]] }
          end
        end

        context 'with multiple string flags' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { %w[flag2 flag3] }
            let(:expected_instances) { [instances[1], instances[2], instances[3], instances[5]] }
          end
        end

        context 'with an invalid symbol flag' do
          it 'raises an error' do
            expect { model.public_send(scope_name, :invalid) }.to raise_error(
              ArgumentError, 'Invalid flag invalid for attribs'
            )
          end
        end

        context 'with an invalid string flag' do
          it 'raises an error' do
            expect { model.public_send(scope_name, 'invalid') }.to raise_error(
              ArgumentError, 'Invalid flag invalid for attribs'
            )
          end
        end
      end

      describe '.all_attribs_enabled' do
        let(:scope_name) { 'all_attribs_enabled' }

        context 'with one symbol flag' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { :flag2 }
            let(:expected_instances) { [instances[0], instances[2], instances[4]] }
          end
        end

        context 'with multiple symbol flags' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { %i[flag2 flag3] }
            let(:expected_instances) { [instances[0], instances[4]] }
          end
        end

        context 'with one string flag' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { 'flag2' }
            let(:expected_instances) { [instances[0], instances[2], instances[4]] }
          end
        end

        context 'with multiple string flags' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { %w[flag2 flag3] }
            let(:expected_instances) { [instances[0], instances[4]] }
          end
        end

        context 'with an invalid symbol flag' do
          it 'raises an error' do
            expect { model.public_send(scope_name, :invalid) }.to raise_error(
              ArgumentError, 'Invalid flag invalid for attribs'
            )
          end
        end

        context 'with an invalid string flag' do
          it 'raises an error' do
            expect { model.public_send(scope_name, 'invalid') }.to raise_error(
              ArgumentError, 'Invalid flag invalid for attribs'
            )
          end
        end
      end

      describe '.all_attribs_disabled' do
        let(:scope_name) { 'all_attribs_disabled' }

        context 'with one symbol flag' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { :flag2 }
            let(:expected_instances) { [instances[1], instances[3], instances[5]] }
          end
        end

        context 'with multiple symbol flags' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { %i[flag2 flag3] }
            let(:expected_instances) { [instances[3]] }
          end
        end

        context 'with one string flag' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { 'flag2' }
            let(:expected_instances) { [instances[1], instances[3], instances[5]] }
          end
        end

        context 'with multiple string flags' do
          it_behaves_like 'scopes correctly' do
            let(:flags) { %w[flag2 flag3] }
            let(:expected_instances) { [instances[3]] }
          end
        end

        context 'with an invalid symbol flag' do
          it 'raises an error' do
            expect { model.public_send(scope_name, :invalid) }.to raise_error(
              ArgumentError, 'Invalid flag invalid for attribs'
            )
          end
        end

        context 'with an invalid string flag' do
          it 'raises an error' do
            expect { model.public_send(scope_name, 'invalid') }.to raise_error(
              ArgumentError, 'Invalid flag invalid for attribs'
            )
          end
        end
      end
    end

    describe '.attribs' do
      it 'returns all defined flags' do
        expect(model.attribs).to eq FLAGS
      end
    end

    context 'when writing to the attribute' do
      shared_examples 'writing to the attribute' do
        context 'when using an integer as the attribute value' do
          let(:value) { 5 }

          it 'correctly sets the attribute' do
            expect(model.first.attribs).to contain_exactly(:flag, :flag3)
          end
        end

        context 'when using an symbol array of flags as the attribute value' do
          let(:value) { %i[flag flag3] }

          it 'correctly sets the attribute' do
            expect(model.first.attribs).to contain_exactly(:flag, :flag3)
          end
        end

        context 'when using a symbol flag as the attribute value' do
          let(:value) { :flag3 }

          it 'correctly sets the attribute' do
            expect(model.first.attribs).to contain_exactly(:flag3)
          end
        end

        context 'when using an string array of flags as the attribute value' do
          let(:value) { %w[flag flag3] }

          it 'correctly sets the attribute' do
            expect(model.first.attribs).to contain_exactly(:flag, :flag3)
          end
        end

        context 'when using a string flag as the attribute value' do
          let(:value) { 'flag3' }

          it 'correctly sets the attribute' do
            expect(model.first.attribs).to contain_exactly(:flag3)
          end
        end

        context 'when using nil as the attribute value' do
          let(:value) { nil }

          it 'correctly sets the attribute' do
            expect(model.first.attribs).to eq []
          end
        end
      end

      describe '.create' do
        before do
          model.create(attribs: value)
        end

        it_behaves_like 'writing to the attribute'
      end

      describe '.create!' do
        before do
          model.create!(attribs: value)
        end

        it_behaves_like 'writing to the attribute'
      end

      describe '.update' do
        let(:instance) { model.create!(attribs: [:flag2]) }

        before do
          instance.update(attribs: value)
        end

        it_behaves_like 'writing to the attribute'
      end

      describe '.update!' do
        let(:instance) { model.create!(attribs: [:flag2]) }

        before do
          instance.update!(attribs: value)
        end

        it_behaves_like 'writing to the attribute'
      end
    end
  end

  context 'when the flags are defined as symbols' do
    it_behaves_like 'sets methods correctly' do
      let(:model) { TestModel }
      let(:table_name) { 'test_models' }
    end
  end

  context 'when the flags are defined as strings' do
    it_behaves_like 'sets methods correctly' do
      let(:model) { StringFlagTestModel }
      let(:table_name) { 'string_flag_test_models' }
    end
  end
end
