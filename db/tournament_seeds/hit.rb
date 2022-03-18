# frozen_string_literal: true

hit = Tournament.create!(
  name: 'Houston Invitational Tournament',
  year: 2022,
  start_date: '2022-07-02',
)

hit.config_items += [
  ConfigItem.new(
    key: 'currency',
    value: 'USD',
  ),
  ConfigItem.new(
    key: 'image_path',
    value: '/images/houston.jpg',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: '4',
  ),
  ConfigItem.new(
    key: 'website',
    value: 'http://www.houstoninvite.com',
  ),
  ConfigItem.new(
    key: 'location',
    value: 'Houston, TX',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-06-29T23:59:59-05:00',
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

hit.contacts += [
  Contact.new(
    name: 'Ron Connors-Elhert',
    email: 'sailingduck55@gmail.com',
    role: :director,
    notify_on_registration: true,
    notify_on_payment: true,
  ),
]

hit.purchasable_items += [
  PurchasableItem.new(
    category: :ledger,
    determination: :entry_fee,
    name: 'Tournament entry fee',
    user_selectable: false,
    value: 100,
  ),
  PurchasableItem.new(
    category: :ledger,
    determination: :late_fee,
    name: 'Late registration fee',
    user_selectable: false,
    value: 20,
    configuration: {
      applies_at: '2022-06-20T04:00:00-05:00',
    },
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
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   name: 'Optional Scratch',
  #   user_selectable: true,
  #   value: 20,
  #   configuration: {
  #     order: 3,
  #   }
  # ),
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
  # ###############################################
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    name: 'Best 3 of 6',
    value: 10,
    configuration: {
      order: 1,
      note: '(Singles / Doubles)',
    }
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    name: 'Best 3 of 9',
    value: 10,
    configuration: {
      order: 2,
    }
  ),
  ##################################################
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Masters',
    value: 40,
    configuration: {
      division: 'A',
      note: '210+',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Masters',
    value: 40,
    configuration: {
      division: 'B',
      note: '190-209',
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
      note: '170-189',
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
      division: 'D',
      note: '150-169',
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
      division: 'E',
      note: '0-149',
    },
  ),
  # #################################################
  # Houston's Optional Scratch is also division-based
  # #################################################
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Optional Scratch',
    user_selectable: true,
    value: 25,
    configuration: {
      division: 'A',
      note: '210+',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Optional Scratch',
    user_selectable: true,
    value: 25,
    configuration: {
      division: 'B',
      note: '190-209',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Optional Scratch',
    user_selectable: true,
    value: 25,
    configuration: {
      division: 'C',
      note: '170-189',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Optional Scratch',
    user_selectable: true,
    value: 25,
    configuration: {
      division: 'D',
      note: '150-169',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Optional Scratch',
    user_selectable: true,
    value: 25,
    configuration: {
      division: 'E',
      note: '0-149',
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
