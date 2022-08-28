# frozen_string_literal: true

module Fixtures
  module Attribute
    def all_enabled_attribs
      '111'
    end

    def all_enabled_but_one_attribs(flag_index)
      attribs = %w[1 1 1]
      attribs[flag_index] = '0'
      attribs.reverse.join
    end

    def all_disabled_but_one_attribs(flag_index)
      attribs = %w[0 0 0]
      attribs[flag_index] = '1'
      attribs.reverse.join
    end

    def all_disabled_attribs
      '000'
    end

    def one_set_others_mixed_attribs(flag_index, enabled: true)
      attribs = %w[0 0 0]
      attribs[flag_index] = enabled ? '1' : '0'
      attribs[(flag_index + 1) % FLAGS.size] = '1'
      attribs[(flag_index + 2) % FLAGS.size] = '0'
      attribs.reverse.join
    end
  end
end
