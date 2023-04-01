# frozen_string_literal: true

module ApparelDetails
  SIZE_CATEGORIES = %i(unisex women men infant)
  SIZES_ADULT = %i(xxs xs s m l xl xxl xxl xxxl)
  SIZES_INFANT = %i(newborn m6 m12 m18 m24)

  def default_size_set
    unisex = HashWithIndifferentAccess[SIZES_ADULT.zip(Array.new(SIZES_ADULT.size, false))]
    women = unisex.deep_dup
    men = unisex.deep_dup
    infant = HashWithIndifferentAccess[SIZES_INFANT.zip(Array.new(SIZES_INFANT.size, false))]

    HashWithIndifferentAccess.new({
      one_size_fits_all: false,
    }).merge({
      unisex: unisex,
      women: women,
      men: men,
      infant: infant,
    })
  end
end
