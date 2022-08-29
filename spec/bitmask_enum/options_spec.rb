# frozen_string_literal: true

require 'fixtures/attribute'

RSpec.describe BitmaskEnum::Options do
  include Fixtures::Attribute

  context 'when flag_prefix is set' do
    after do
      ActiveRecord::Base.connection.execute('DELETE FROM prefix_test_models')
    end

    let(:instance) { PrefixTestModel.create!(attribs: all_enabled_attribs.to_i(2)) }

    FLAGS.each do |flag|
      describe "#pre_#{flag}?" do
        it 'constructs the method with the prefix' do
          expect(instance.public_send("pre_#{flag}?")).to be true
        end
      end

      describe "#pre_#{flag}!" do
        it 'constructs the method with the prefix' do
          instance.public_send("pre_#{flag}!")

          expect(instance.public_send("pre_#{flag}?")).to be false
        end
      end

      describe "#enable_pre_#{flag}!" do
        it 'constructs the method with the prefix' do
          instance.public_send("enable_pre_#{flag}!")

          expect(instance.public_send("pre_#{flag}?")).to be true
        end
      end

      describe "#disable_pre_#{flag}!" do
        it 'constructs the method with the prefix' do
          instance.public_send("disable_pre_#{flag}!")

          expect(instance.public_send("pre_#{flag}?")).to be false
        end
      end

      describe 'scopes' do
        let(:instances) do
          [
            PrefixTestModel.create!(attribs: all_enabled_attribs.to_i(2)),
            PrefixTestModel.create!(attribs: all_disabled_attribs.to_i(2))
          ]
        end

        describe ".pre_#{flag}_enabled" do
          it 'constructs the scope with the prefix' do
            expect(PrefixTestModel.public_send("pre_#{flag}_enabled")).to contain_exactly(
              instances[0]
            )
          end
        end

        describe ".pre_#{flag}_disabled" do
          it 'constructs the scope with the prefix' do
            expect(PrefixTestModel.public_send("pre_#{flag}_disabled")).to contain_exactly(
              instances[1]
            )
          end
        end
      end
    end
  end

  context 'when flag_suffix is set' do
    after do
      ActiveRecord::Base.connection.execute('DELETE FROM suffix_test_models')
    end

    let(:instance) { SuffixTestModel.create!(attribs: all_enabled_attribs.to_i(2)) }

    FLAGS.each do |flag|
      describe "##{flag}_post?" do
        it 'constructs the method with the prefix' do
          expect(instance.public_send("#{flag}_post?")).to be true
        end
      end

      describe "##{flag}_post!" do
        it 'constructs the method with the prefix' do
          instance.public_send("#{flag}_post!")

          expect(instance.public_send("#{flag}_post?")).to be false
        end
      end

      describe "#enable_#{flag}_post!" do
        it 'constructs the method with the prefix' do
          instance.public_send("enable_#{flag}_post!")

          expect(instance.public_send("#{flag}_post?")).to be true
        end
      end

      describe "#disable_#{flag}_post!" do
        it 'constructs the method with the prefix' do
          instance.public_send("disable_#{flag}_post!")

          expect(instance.public_send("#{flag}_post?")).to be false
        end
      end

      describe 'scopes' do
        let(:instances) do
          [
            SuffixTestModel.create!(attribs: all_enabled_attribs.to_i(2)),
            SuffixTestModel.create!(attribs: all_disabled_attribs.to_i(2))
          ]
        end

        describe ".#{flag}_post_enabled" do
          it 'constructs the scope with the prefix' do
            expect(SuffixTestModel.public_send("#{flag}_post_enabled")).to contain_exactly(
              instances[0]
            )
          end
        end

        describe ".#{flag}_post_disabled" do
          it 'constructs the scope with the prefix' do
            expect(SuffixTestModel.public_send("#{flag}_post_disabled")).to contain_exactly(
              instances[1]
            )
          end
        end
      end
    end
  end

  context 'when validate is not set' do
    after do
      ActiveRecord::Base.connection.execute('DELETE FROM test_models')
    end

    context 'when using setting the attribute value above the maximum valid value' do
      let(:instance) { TestModel.create!(attribs: [:flag2]) }

      it 'raises an error' do
        expect { instance.update!(attribs: (1 << FLAGS.size)) }.to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: Attribs must be less than 8'
        )
      end
    end
  end

  context 'when validate is true' do
    after do
      ActiveRecord::Base.connection.execute('DELETE FROM validate_true_test_models')
    end

    context 'when using setting the attribute value above the maximum valid value' do
      let(:instance) { ValidateTrueTestModel.create!(attribs: [:flag2]) }

      it 'raises an error' do
        expect { instance.update!(attribs: (1 << FLAGS.size)) }.to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: Attribs must be less than 8'
        )
      end
    end
  end

  context 'when validate is false' do
    after do
      ActiveRecord::Base.connection.execute('DELETE FROM validate_false_test_models')
    end

    context 'when using setting the attribute value above the maximum valid value' do
      let(:instance) { ValidateFalseTestModel.create!(attribs: [:flag2]) }

      before do
        instance.update!(attribs: (1 << FLAGS.size))
      end

      it 'sets the value' do
        expect(ValidateFalseTestModel.first.attribs).to eq []
      end
    end
  end
end
