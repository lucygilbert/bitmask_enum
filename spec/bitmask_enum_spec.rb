RSpec.describe BitmaskEnum do
  FLAGS = [:flag, :flag2, :flag3]

  after(:each) do
    ActiveRecord::Base.connection.execute('DELETE FROM test_models')
  end

  it 'has a version number' do
    expect(BitmaskEnum::VERSION).to eq '0.1.0'
  end

  context 'when the definition is valid' do
    class TestModel < ActiveRecord::Base
      bitmask_enum attribs: FLAGS
    end

    def expect_other_flags_unchanged(method_name, flag, model)
      initial_values = current_flag_settings_excluding(flag, model)

      model.public_send(method_name)

      post_action_values = current_flag_settings_excluding(flag, model)

      expect(post_action_values).to eq(initial_values)
    end

    def current_flag_settings_excluding(flag, model)
      (FLAGS - [flag]).map do |other_flag|
        model.public_send("#{other_flag}?")
      end
    end

    def all_enabled_attribs
      '111'
    end

    def all_enabled_but_one_attribs(i)
      attribs = '111'
      attribs[i] = '0'
      attribs.reverse
    end

    def all_disabled_but_one_attribs(i)
      attribs = '000'
      attribs[i] = '1'
      attribs.reverse
    end

    def all_disabled_attribs
      '000'
    end

    def one_set_others_mixed_attribs(i, enabled = true)
      attribs = '000'
      attribs[i] = enabled ? '1' : '0'
      attribs[(i + 1) % FLAGS.size] = '1'
      attribs[(i + 2) % FLAGS.size] = '0'
      attribs.reverse
    end

    FLAGS.each_with_index do |flag, i|
      describe "##{flag}?" do
        shared_examples 'checking the flag' do
          context 'when the flag is enabled' do
            subject(:model) { TestModel.create!(attribs: enabled_attribs.to_i(2)) }

            it 'returns true' do
              expect(model.public_send("#{flag}?")).to be true
            end

            it 'is idempotent' do
              expect(model.public_send("#{flag}?")).to be true
              expect(model.public_send("#{flag}?")).to be true
            end

            it 'does not affect other flags' do
              expect_other_flags_unchanged("#{flag}?", flag, model)
            end
          end

          context 'when the flag is disabled' do
            subject(:model) { TestModel.create!(attribs: disabled_attribs.to_i(2)) }

            it 'returns false' do
              expect(model.public_send("#{flag}?")).to be false
            end

            it 'is idempotent' do
              expect(model.public_send("#{flag}?")).to be false
              expect(model.public_send("#{flag}?")).to be false
            end

            it 'does not affect other flags' do
              expect_other_flags_unchanged("#{flag}?", flag, model)
            end
          end
        end

        
        context 'when all other flags are enabled' do
          it_behaves_like 'checking the flag' do
            let(:enabled_attribs) { all_enabled_attribs }
            let(:disabled_attribs) { all_enabled_but_one_attribs(i) }
          end
        end

        context 'when all other flags are disabled' do
          it_behaves_like 'checking the flag' do
            let(:enabled_attribs) { all_disabled_but_one_attribs(i) }
            let(:disabled_attribs) { all_disabled_attribs }
          end
        end

        context 'when other flags have a mix of settings' do
          it_behaves_like 'checking the flag' do
            let(:enabled_attribs) { one_set_others_mixed_attribs(i) }
            let(:disabled_attribs) { one_set_others_mixed_attribs(i, false) }
          end
        end
      end

      describe "##{flag}!" do
        shared_examples 'toggling the flag' do
          context 'when the flag is enabled' do
            subject(:model) { TestModel.create!(attribs: enabled_attribs.to_i(2)) }

            it 'disables the flag' do
              model.public_send("#{flag}!")

              expect(model.public_send("#{flag}?")).to be false
            end

            it 'does not affect other flags' do
              expect_other_flags_unchanged("#{flag}!", flag, model)
            end
          end

          context 'when the flag is disabled' do
            subject(:model) { TestModel.create!(attribs: disabled_attribs.to_i(2)) }

            it 'enables the flag' do
              model.public_send("#{flag}!")

              expect(model.public_send("#{flag}?")).to be true
            end

            it 'does not affect other flags' do
              expect_other_flags_unchanged("#{flag}!", flag, model)
            end
          end
        end

        context 'when all other flags are enabled' do
          it_behaves_like 'toggling the flag' do
            let(:enabled_attribs) { all_enabled_attribs }
            let(:disabled_attribs) { all_enabled_but_one_attribs(i) }
          end
        end

        context 'when all other flags are disabled' do
          it_behaves_like 'toggling the flag' do
            let(:enabled_attribs) { all_disabled_but_one_attribs(i) }
            let(:disabled_attribs) { all_disabled_attribs }
          end
        end

        context 'when other flags have a mix of settings' do
          it_behaves_like 'toggling the flag' do
            let(:enabled_attribs) { one_set_others_mixed_attribs(i) }
            let(:disabled_attribs) { one_set_others_mixed_attribs(i, false) }
          end
        end
      end

      describe "#enable_#{flag}!" do
        shared_examples 'enabling the flag' do
          context 'when the flag is enabled' do
            subject(:model) { TestModel.create!(attribs: enabled_attribs.to_i(2)) }

            it 'does nothing' do
              model.public_send("enable_#{flag}!")

              expect(model.public_send("#{flag}?")).to be true
            end

            it 'does not affect other flags' do
              expect_other_flags_unchanged("enable_#{flag}!", flag, model)
            end
          end

          context 'when the flag is disabled' do
            subject(:model) { TestModel.create!(attribs: disabled_attribs.to_i(2)) }

            it 'enables the flag' do
              model.public_send("enable_#{flag}!")

              expect(model.public_send("#{flag}?")).to be true
            end

            it 'does not affect other flags' do
              expect_other_flags_unchanged("enable_#{flag}!", flag, model)
            end
          end
        end

        context 'when all other flags are enabled' do
          it_behaves_like 'enabling the flag' do
            let(:enabled_attribs) { all_enabled_attribs }
            let(:disabled_attribs) { all_enabled_but_one_attribs(i) }
          end
        end

        context 'when all other flags are disabled' do
          it_behaves_like 'enabling the flag' do
            let(:enabled_attribs) { all_disabled_but_one_attribs(i) }
            let(:disabled_attribs) { all_disabled_attribs }
          end
        end

        context 'when other flags have a mix of settings' do
          it_behaves_like 'enabling the flag' do
            let(:enabled_attribs) { one_set_others_mixed_attribs(i) }
            let(:disabled_attribs) { one_set_others_mixed_attribs(i, false) }
          end
        end
      end

      describe "#disable_#{flag}!" do
        shared_examples 'disabling the flag' do
          context 'when the flag is enabled' do
            subject(:model) { TestModel.create!(attribs: enabled_attribs.to_i(2)) }

            it 'disables the flag' do
              model.public_send("disable_#{flag}!")

              expect(model.public_send("#{flag}?")).to be false
            end

            it 'does not affect other flags' do
              expect_other_flags_unchanged("disable_#{flag}!", flag, model)
            end
          end

          context 'when the flag is disabled' do
            subject(:model) { TestModel.create!(attribs: disabled_attribs.to_i(2)) }

            it 'does nothing' do
              model.public_send("disable_#{flag}!")

              expect(model.public_send("#{flag}?")).to be false
            end

            it 'does not affect other flags' do
              expect_other_flags_unchanged("disable_#{flag}!", flag, model)
            end
          end
        end

        context 'when all other flags are enabled' do
          it_behaves_like 'disabling the flag' do
            let(:enabled_attribs) { all_enabled_attribs }
            let(:disabled_attribs) { all_enabled_but_one_attribs(i) }
          end
        end

        context 'when all other flags are disabled' do
          it_behaves_like 'disabling the flag' do
            let(:enabled_attribs) { all_disabled_but_one_attribs(i) }
            let(:disabled_attribs) { all_disabled_attribs }
          end
        end

        context 'when other flags have a mix of settings' do
          it_behaves_like 'disabling the flag' do
            let(:enabled_attribs) { one_set_others_mixed_attribs(i) }
            let(:disabled_attribs) { one_set_others_mixed_attribs(i, false) }
          end
        end
      end

      context 'scopes' do
        let(:models) do
          [
            TestModel.create!(attribs: all_enabled_attribs.to_i(2)),
            TestModel.create!(attribs: all_enabled_but_one_attribs(i).to_i(2)),
            TestModel.create!(attribs: all_disabled_but_one_attribs(i).to_i(2)),
            TestModel.create!(attribs: all_disabled_attribs.to_i(2)),
            TestModel.create!(attribs: one_set_others_mixed_attribs(i).to_i(2)),
            TestModel.create!(attribs: one_set_others_mixed_attribs(i, false).to_i(2))
          ]
        end

        describe ".#{flag}_enabled" do
          it 'returns all records for which the flag is enabled' do
            expect(TestModel.public_send("#{flag}_enabled")).to contain_exactly(
              models[0], models[2], models[4]
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
              models[1], models[3], models[5]
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
        subject(:model) { TestModel.create!(attribs: all_enabled_attribs.to_i(2)) }

        it 'returns a hash with all flags set to true' do
          expect(model.attribs_settings).to eq(flag: true, flag2: true, flag3: true)
        end
      end

      context 'when all flags are disabled' do
        subject(:model) { TestModel.create!(attribs: all_disabled_attribs.to_i(2)) }

        it 'returns a hash with all flags set to false' do
          expect(model.attribs_settings).to eq(flag: false, flag2: false, flag3: false)
        end
      end

      context 'when flags have a mix of settings' do
        subject(:model) { TestModel.create!(attribs: one_set_others_mixed_attribs(2).to_i(2)) }

        it 'returns a hash with flags set to the correct values' do
          expect(model.attribs_settings).to eq(flag: true, flag2: false, flag3: true)
        end
      end
    end

    describe '#attribs' do
      context 'when all flags are enabled' do
        subject(:model) { TestModel.create!(attribs: all_enabled_attribs.to_i(2)) }

        it 'returns an array of all flags' do
          expect(model.attribs).to eq [:flag, :flag2, :flag3]
        end
      end

      context 'when all flags are disabled' do
        subject(:model) { TestModel.create!(attribs: all_disabled_attribs.to_i(2)) }

        it 'returns an empty array' do
          expect(model.attribs).to eq []
        end
      end

      context 'when flags have a mix of settings' do
        subject(:model) { TestModel.create!(attribs: one_set_others_mixed_attribs(2).to_i(2)) }

        it 'returns an array of only the enabled flags' do
          expect(model.attribs).to eq [:flag, :flag3]
        end
      end
    end

    describe '.attribs' do
      it 'returns all defined flags' do
        expect(TestModel.attribs).to eq FLAGS
      end
    end
  end

  context 'when the definition is invalid' do
    context 'with a definition that is not a hash' do
      it 'raises an error' do
        expect do
          Class.new(ActiveRecord::Base) do
            def self.name
              'TestModel'
            end

            bitmask_enum 'not_hash'
          end
        end.to raise_error(
          BitmaskEnum::BitmaskEnumInvalidError,
          'BitmaskEnum definition is invalid: must be a hash'
        )
      end
    end

    context 'with a definition with multiple keys' do
      it 'raises an error' do
        expect do
          Class.new(ActiveRecord::Base) do
            def self.name
              'TestModel'
            end

            bitmask_enum attribs: [:flag_one], another: [:flag_two]
          end
        end.to raise_error(
          BitmaskEnum::BitmaskEnumInvalidError,
          'BitmaskEnum definition is invalid: must have one key'
        )
      end
    end

    context 'with a definition whose first value is not an array of symbols or strings' do
      it 'raises an error' do
        expect do
          Class.new(ActiveRecord::Base) do
            def self.name
              'TestModel'
            end

            bitmask_enum attribs: { abc: 123 }
          end
        end.to raise_error(
          BitmaskEnum::BitmaskEnumInvalidError,
          'BitmaskEnum definition is invalid: must provide a symbol or string array of flags'
        )
      end
    end
  end

  context 'when methods conflict' do
    context 'at the class level' do
      context 'when the method exists in ActiveRecord' do
        it 'raises an error' do
          expect do
            Class.new(ActiveRecord::Base) do
              def self.name
                'TestModel'
              end

              bitmask_enum create: [:flag]
            end
          end.to raise_error(
            BitmaskEnum::BitmaskEnumMethodConflictError,
            'BitmaskEnum method definition is conflicting: ' \
            'class method: create for enum: create in class: TestModel ' \
            'is already defined by: ActiveRecord'
          )
        end
      end

      context 'when the method exists in ActiveRecord::Relation' do
        it 'raises an error' do
          expect do
            Class.new(ActiveRecord::Base) do
              def self.name
                'TestModel'
              end

              bitmask_enum values: [:flag]
            end
          end.to raise_error(
            BitmaskEnum::BitmaskEnumMethodConflictError,
            'BitmaskEnum method definition is conflicting: ' \
            'class method: values for enum: values in class: TestModel ' \
            'is already defined by: ActiveRecord::Relation'
          )
        end
      end
    end

    context 'at the instance level' do
      context 'when the method exists in ActiveRecord' do
        it 'raises an error' do
          expect do
            Class.new(ActiveRecord::Base) do
              def self.name
                'TestModel'
              end

              bitmask_enum attribs: [:destroyed]
            end
          end.to raise_error(
            BitmaskEnum::BitmaskEnumMethodConflictError,
            'BitmaskEnum method definition is conflicting: ' \
            'method: destroyed? for enum: attribs in class: TestModel ' \
            'is already defined by: ActiveRecord'
          )
        end
      end

      context 'when the method exists in another enum' do
        it 'raises an error' do
          expect do
            Class.new(ActiveRecord::Base) do
              def self.name
                'TestModel'
              end

              bitmask_enum other_int: [:flag]
              bitmask_enum attribs: [:flag]
            end
          end.to raise_error(
            BitmaskEnum::BitmaskEnumMethodConflictError,
            'BitmaskEnum method definition is conflicting: ' \
            'method: flag? for enum: attribs in class: TestModel ' \
            'is already defined by: other_int'
          )
        end
      end
    end
  end
end
