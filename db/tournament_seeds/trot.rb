# frozen_string_literal: true

trot = Tournament.create!(
  name: 'Texas Roll Off Tournament',
  year: 2022,
  start_date: '2022-02-18',
)

trot.config_items += [
  ConfigItem.new(
    key: 'currency',
    value: 'USD',
  ),
  ConfigItem.new(
    key: 'image_path',
    value: '/images/trot.png',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: '4',
  ),
  ConfigItem.new(
    key: 'website',
    value: 'http://trotbowling.com/',
  ),
  ConfigItem.new(
    key: 'location',
    value: 'Grand Prairie, TX',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2021-02-06T23:59:59-06:00',
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

trot.contacts += [
  Contact.new(
    name: 'Donetta Fleming',
    email: 'director@trotbowling.com',
    notes: 'Director',
    role: :director,
  ),
  Contact.new(
    name: 'Larry Fewell',
    email: 'secretary@trotbowling.com',
    notes: 'Secretary',
    role: :secretary,
    notify_on_registration: true,
  ),
  Contact.new(
    name: 'Joseph Puckett',
    email: 'treasurer@trotbowling.com',
    notes: 'Treasurer',
    role: :treasurer,
    notify_on_payment: true,
  ),
]

eff = ExtendedFormField.find_by(name: 'pronouns')
trot.additional_questions << AdditionalQuestion.new(
  extended_form_field: eff,
  validation_rules: eff.validation_rules,
  order: 1,
)
eff = ExtendedFormField.find_by(name: 'comment')
trot.additional_questions << AdditionalQuestion.new(
  extended_form_field: eff,
  validation_rules: eff.validation_rules,
  order: 2,
)

trot.purchasable_items += [
  PurchasableItem.new(
    category: :ledger,
    determination: :entry_fee,
    name: 'Tournament entry fee',
    user_selectable: false,
    value: 110,
  ),
  PurchasableItem.new(
    category: :ledger,
    determination: :early_discount,
    name: 'Early registration discount',
    user_selectable: false,
    value: -10,
    configuration: {
      valid_until: '2022-01-24T00:00:00-06:00',
    },
  ),
  PurchasableItem.new(
    category: :ledger,
    determination: :discount_expiration,
    name: 'Early registration discount expiration',
    user_selectable: false,
    value: 10,
  ),
  # PurchasableItem.new(
  #   category: :ledger,
  #   determination: :late_fee,
  #   name: 'Late registration fee',
  #   user_selectable: false,
  #   value: 10,
  #   configuration: {
  #     applies_at: '2022-02-01T04:00:00-06:00',
  #   },
  # ),
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
    name: 'Optional Scratch',
    user_selectable: true,
    value: 20,
    configuration: {
      order: 3,
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
  #   value: 20,
  #   configuration: {
  #     order: 7,
  #   }
  # ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    name: 'Best 3 Across 9',
    user_selectable: true,
    value: 10,
    configuration: {
      order: 8,
    }
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    name: 'Mystery Score',
    user_selectable: true,
    value: 10,
    configuration: {
      order: 9,
    }
  ),
# PurchasableItem.new(
#   category: :bowling,
#   determination: :single_use,
#   refinement: :division,
#   name: 'Scratch Masters',
#   user_selectable: true,
#   value: 40,
#   configuration: {
#     division: 'A',
#     note: '201+',
#   },
# ),
# PurchasableItem.new(
#   category: :bowling,
#   determination: :single_use,
#   refinement: :division,
#   name: 'Scratch Masters',
#   user_selectable: true,
#   value: 40,
#   configuration: {
#     division: 'B',
#     note: '186-200',
#   },
# ),
# PurchasableItem.new(
#   category: :bowling,
#   determination: :single_use,
#   refinement: :division,
#   name: 'Scratch Masters',
#   user_selectable: true,
#   value: 40,
#   configuration: {
#     division: 'C',
#     note: '171-185',
#   },
# ),
# PurchasableItem.new(
#   category: :bowling,
#   determination: :single_use,
#   refinement: :division,
#   name: 'Scratch Masters',
#   user_selectable: true,
#   value: 40,
#   configuration: {
#     division: 'D',
#     note: '156-170',
#   },
# ),
# PurchasableItem.new(
#   category: :bowling,
#   determination: :single_use,
#   refinement: :division,
#   name: 'Scratch Masters',
#   user_selectable: true,
#   value: 40,
#   configuration: {
#     division: 'E',
#     note: '0-155',
#   },
# ),
# PurchasableItem.new(
#   category: :banquet,
#   determination: :multi_use,
#   name: 'Banquet Entry (non-bowler)',
#   user_selectable: true,
#   value: 20,
# ),
]
