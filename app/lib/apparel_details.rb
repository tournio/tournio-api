# frozen_string_literal: true

module ApparelDetails
  SIZE_CATEGORIES = %i(unisex women men infant)
  SIZES_ADULT = %i(xxs xs s m l xl xxl xxl xxxl xxxxl)
  SIZES_INFANT = %i(newborn m6 m12 m18 m24)

  SIZE_STRINGS = {
    xxs: '2XS',
    xs: 'XS',
    s: 'S',
    m: 'M',
    l: 'L',
    xl: 'XL',
    xxl: '2XL',
    xxxl: '3XL',
    xxxxl: '4XL',
    newborn: 'Newborn',
    m6: '6 months',
    m12: '12 months',
    m18: '18 months',
    m24: '24 months',
  }

  def self.default_size_set
    unisex = HashWithIndifferentAccess[SIZES_ADULT.zip(Array.new(SIZES_ADULT.size, false))]
    women = unisex.deep_dup
    men = unisex.deep_dup
    infant = HashWithIndifferentAccess[SIZES_INFANT.zip(Array.new(SIZES_INFANT.size, false))]

    HashWithIndifferentAccess.new({
      unisex: unisex,
      women: women,
      men: men,
      infant: infant,
    })
  end

  def self.serialize_size(group_key, size_key)
    "#{group_key}.#{size_key}"
  end

  def self.humanize_size(serialized_size)
    parts = serialized_size.split('.')
    "#{parts[0].titleize} #{SIZE_STRINGS[parts[1]&.to_sym]}".strip
  end
end
