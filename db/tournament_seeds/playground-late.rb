# frozen_string_literal: true

playground = Tournament.create!(
  name: 'Late Playground Tournament',
  year: 2022,
  start_date: '2022-04-01',
)

playground.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'Atlanta, GA',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-03-24T23:59:59-04:00',
  ),
  ConfigItem.new(
    key: 'time_zone',
    value: 'America/New_York',
  ),
  ConfigItem.new(
    key: 'image_path',
    value: '/images/generic.jpg',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: 4,
  ),
  ConfigItem.new(
    key: 'website',
    value: 'http://www.goldengateclassic.org',
  ),
  ConfigItem.new(
    key: 'paypal_client_id',
    value: 'sb',
  ),
  ConfigItem.new(
    key: 'email_in_dev',
    value: 'false',
  ),
]

playground.contacts << Contact.new(
  name: 'Kylie Minogue',
  email: 'director@playground.org',
  notes: 'Purser',
)
playground.contacts << Contact.new(
  name: 'Dua Lipa',
  email: 'architect@playground.org',
  notes: 'Architect',
)
playground.contacts << Contact.new(
  name: 'Tom Aspaul',
  email: 'musicman@playground.org',
  notes: 'Musical Director',
)

playground.purchasable_items += [
  PurchasableItem.new(
    category: :ledger,
    determination: :entry_fee,
    name: 'Tournament entry fee',
    user_selectable: false,
    value: 100,
  ),
  # PurchasableItem.new(
  #   category: :ledger,
  #   determination: :early_discount,
  #   name: 'Early registration discount',
  #   user_selectable: false,
  #   value: -10,
  #   configuration: {
  #     valid_until: '2021-12-04T00:00:00-04:00',
  #   },
  # ),
  PurchasableItem.new(
    category: :ledger,
    determination: :late_fee,
    name: 'Late registration fee',
    user_selectable: false,
    value: 12,
    configuration: {
      applies_at: '2022-03-01T00:00:00-04:00',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    name: 'Optional Scratch',
    user_selectable: true,
    value: 20,
    configuration: {
      order: 3,
    }
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    name: 'Optional Handicap',
    user_selectable: true,
    value: 20,
    configuration: {
      order: 4,
    }
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    name: 'Scratch Side Pots',
    user_selectable: true,
    value: 30,
    configuration: {
      order: 5,
    }
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    name: 'Handicap Side Pots',
    user_selectable: true,
    value: 30,
    configuration: {
      order: 6,
    }
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Masters',
    user_selectable: true,
    value: 40,
    configuration: {
      division: 'E: Eager Beavers',
      note: '0-149',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Masters',
    user_selectable: true,
    value: 50,
    configuration: {
      division: 'D: Dorky Dannies',
      note: '150-169',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Masters',
    user_selectable: true,
    value: 50,
    configuration: {
      division: 'C: Cranky Pants',
      note: '170-189',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Masters',
    user_selectable: true,
    value: 60,
    configuration: {
      division: 'B: Beager Eavers',
      note: '190-208',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Masters',
    user_selectable: true,
    value: 60,
    configuration: {
      division: 'A: Awesome Sauces',
      note: '209+',
    },
  ),
  PurchasableItem.new(
    category: :banquet,
    determination: :multi_use,
    name: 'Banquet Entry (non-bowler)',
    user_selectable: true,
    value: 40,
  ),
]
