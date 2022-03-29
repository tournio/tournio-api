# frozen_string_literal: true

tss = Tournament.create!(
  name: 'Texas Super Slam',
  year: 2022,
  start_date: '2022-09-02',
)

tss.config_items += [
  ConfigItem.new(
    key: 'image_path',
    value: '/images/txsuperslam.webp',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: '4',
  ),
  ConfigItem.new(
    key: 'website',
    value: 'https://www.txsuperslam.com/',
  ),
  ConfigItem.new(
    key: 'location',
    value: 'Austin, TX',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-08-24T23:59:59-05:00',
  ),
  ConfigItem.new(
    key: 'time_zone',
    value: 'America/Chicago',
  ),
  ConfigItem.new(
    key: 'paypal_client_id',
    value: 'sb',
  ),
]

tss.contacts += [
  Contact.new(
    name: 'Michael Riley',
    email: 'mpriley1138@gmail.com',
    role: :director,
  ),
  Contact.new(
    name: 'Fred Waterman',
    email: 'fred.waterman@icloud.com',
    role: :'secretary-treasurer',
    notify_on_registration: true,
    notify_on_payment: true,
    notification_preference: :daily_summary,
  ),
  Contact.new(
    name: 'Brian Hamburg',
    email: 'txgameshowfan@mac.com',
    role: :statistician,
  ),
  Contact.new(
    name: 'James Thigpen',
    email: 'james.b.thigpen@gmail.com',
    role: :fundraising,
  ),

]

tss.purchasable_items += [
  PurchasableItem.new(
    category: :ledger,
    determination: :entry_fee,
    name: 'Tournament entry fee',
    user_selectable: false,
    value: 105,
  ),
  # PurchasableItem.new(
  #   category: :ledger,
  #   determination: :late_fee,
  #   name: 'Late registration fee',
  #   user_selectable: false,
  #   value: 15,
  #   configuration: {
  #     applies_at: '2021-06-24T04:00:00-05:00',
  #   },
  # ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   name: 'Friday night 9-pin No-tap',
  #   user_selectable: true,
  #   value: 25,
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
    name: 'Optional Scratch',
    user_selectable: true,
    value: 30,
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
    name: 'Scratch Masters',
    user_selectable: true,
    value: 50,
    configuration: {
      division: 'A',
      note: '205+',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Masters',
    user_selectable: true,
    value: 45,
    configuration: {
      division: 'B',
      note: '190-204',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Masters',
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
    name: 'Scratch Masters',
    user_selectable: true,
    value: 35,
    configuration: {
      division: 'D',
      note: '160-174',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Masters',
    user_selectable: true,
    value: 30,
    configuration: {
      division: 'E',
      note: '0-159',
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
