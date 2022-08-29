# frozen_string_literal: true

RSpec.describe BitmaskEnum do
  it 'has a version number' do
    expect(BitmaskEnum::VERSION).to eq '0.4.0'
  end

  context 'when the definition is valid' do
    let(:attribute) { instance_double(described_class::Attribute) }

    before do
      allow(described_class::Attribute).to receive(:new).and_return(attribute)
      allow(attribute).to receive(:construct!)
    end

    context 'with no options provided' do
      before do
        Class.new(ActiveRecord::Base) do
          bitmask_enum attribs: [:flag]
        end
      end

      it 'initializes an attribute with the default options' do
        expect(described_class::Attribute).to have_received(:new).with(
          Class,
          :attribs,
          [:flag],
          { flag_prefix: nil, flag_suffix: nil, nil_handling: :include, validate: true },
          {}
        )
      end

      it 'constructs the attribute' do
        expect(attribute).to have_received(:construct!)
      end
    end

    context 'with options provided' do
      before do
        Class.new(ActiveRecord::Base) do
          bitmask_enum attribs: [:flag], flag_prefix: 'type'
        end
      end

      it 'constructs an attribute with the provided options with the defaults merged in' do
        expect(described_class::Attribute).to have_received(:new).with(
          Class,
          :attribs,
          [:flag],
          { flag_prefix: 'type', flag_suffix: nil, nil_handling: :include, validate: true },
          {}
        )
      end

      it 'constructs the attribute' do
        expect(attribute).to have_received(:construct!)
      end
    end
  end

  context 'when the definition is invalid' do
    context 'with params that are not a hash' do
      let(:expected_error_type) { BitmaskEnum::BitmaskEnumInvalidError }
      let(:expected_error_message) { 'BitmaskEnum definition is invalid: must be a hash' }

      it 'raises an error' do
        expect do
          Class.new(ActiveRecord::Base) do
            bitmask_enum 'not_hash'
          end
        end.to raise_error(expected_error_type, expected_error_message)
      end
    end

    context 'with an attribute that is not symbol or string' do
      let(:expected_error_type) { BitmaskEnum::BitmaskEnumInvalidError }
      let(:expected_error_message) do
        'BitmaskEnum definition is invalid: attribute must be a symbol or string and cannot be empty'
      end

      it 'raises an error' do
        expect do
          Class.new(ActiveRecord::Base) do
            bitmask_enum({ 2 => [:flag] })
          end
        end.to raise_error(expected_error_type, expected_error_message)
      end
    end

    context 'with an attribute that is empty' do
      let(:expected_error_type) { BitmaskEnum::BitmaskEnumInvalidError }
      let(:expected_error_message) do
        'BitmaskEnum definition is invalid: attribute must be a symbol or string and cannot be empty'
      end

      it 'raises an error' do
        expect do
          Class.new(ActiveRecord::Base) do
            bitmask_enum({ '' => [:flag] })
          end
        end.to raise_error(expected_error_type, expected_error_message)
      end
    end

    context 'with flags that are not an array' do
      let(:expected_error_type) { BitmaskEnum::BitmaskEnumInvalidError }
      let(:expected_error_message) do
        'BitmaskEnum definition is invalid: must provide a symbol or string array of flags'
      end

      it 'raises an error' do
        expect do
          Class.new(ActiveRecord::Base) do
            bitmask_enum attribs: { abc: 123 }
          end
        end.to raise_error(expected_error_type, expected_error_message)
      end
    end

    context 'with flags that are not an array of symbols or strings' do
      let(:expected_error_type) { BitmaskEnum::BitmaskEnumInvalidError }
      let(:expected_error_message) do
        'BitmaskEnum definition is invalid: must provide a symbol or string array of flags'
      end

      it 'raises an error' do
        expect do
          Class.new(ActiveRecord::Base) do
            bitmask_enum attribs: [2, 3]
          end
        end.to raise_error(expected_error_type, expected_error_message)
      end
    end
  end
end
