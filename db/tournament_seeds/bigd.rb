# frozen_string_literal: true

bigd = Tournament.create!(
  name: 'Big D Classic',
  year: 2022,
  start_date: '2022-08-12',
)

bigd.config_items += [
  ConfigItem.new(
    key: 'image_path',
    value: '/images/bigdclassic.jpg',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: '4',
  ),
  ConfigItem.new(
    key: 'website',
    value: 'http://www.bigdclassic.com',
  ),
  ConfigItem.new(
    key: 'location',
    value: 'Dallas, TX',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-08-03T23:59:59-05:00',
  ),
  ConfigItem.new(
    key: 'time_zone',
    value: 'America/Chicago',
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

bigd.contacts += [
  Contact.new(
    name: 'Randall Buda',
    email: 'directors@bigdclassic.com',
    role: :'co-director',
    notify_on_registration: true,
    notify_on_payment: true,
  ),
  Contact.new(
    name: 'José Aguilar',
    email: 'directors@bigdclassic.com',
    role: :'co-director',
  ),
]

bigd.purchasable_items += [
  PurchasableItem.new(
    category: :ledger,
    determination: :entry_fee,
    name: 'Tournament entry fee',
    user_selectable: false,
    value: 105,
  ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   name: 'Thursday night 9-pin No-tap',
  #   user_selectable: true,
  #   value: 20,
  #   configuration: {
  #     order: 1,
  #   }
  # ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   name: "Women's Optional",
  #   user_selectable: true,
  #   value: 20,
  #   configuration: {
  #     order: 2,
  #   }
  # ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    name: 'Traditional Scratch',
    user_selectable: true,
    value: 20,
    configuration: {
      order: 1,
    }
  ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   name: 'Optional Handicap',
  #   user_selectable: true,
  #   value: 20,
  #   configuration: {
  #     order: 4,
  #   }
  # ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   name: 'Scratch Side Pots',
  #   user_selectable: true,
  #   value: 30,
  #   configuration: {
  #     order: 5,
  #   }
  # ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   name: 'Handicap Side Pots',
  #   user_selectable: true,
  #   value: 30,
  #   configuration: {
  #     order: 6,
  #   }
  # ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   name: 'Mystery Doubles',
  #   user_selectable: true,
  #   value: 10,
  #   configuration: {
  #     order: 7,
  #   }
  # ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   name: 'Best 3 Across 9',
  #   user_selectable: true,
  #   value: 20,
  #   configuration: {
  #     order: 8,
  #   }
  # ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Shootout',
    user_selectable: true,
    value: 30,
    configuration: {
      division: 'E',
      note: '0-154',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Shootout',
    user_selectable: true,
    value: 30,
    configuration: {
      division: 'D',
      note: '155-174',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Shootout',
    user_selectable: true,
    value: 40,
    configuration: {
      division: 'C',
      note: '175-189',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Shootout',
    user_selectable: true,
    value: 40,
    configuration: {
      division: 'B',
      note: '190-204',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Shootout',
    user_selectable: true,
    value: 50,
    configuration: {
      division: 'A',
      note: '205+',
    },
  ),
  # PurchasableItem.new(
  #   category: :banquet,
  #   determination: :multi_use,
  #   name: 'Banquet Entry (non-bowler)',
  #   user_selectable: true,
  #   value: 20,
  # ),
]
