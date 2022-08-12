# frozen_string_literal: true

okc = Tournament.create!(
  name: 'OK Classic',
  year: 2023,
  start_date: '2023-04-21',
)

okc.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'Oklahoma City, OK',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2023-04-03T23:59:59-05:00',
  ),
  ConfigItem.new(
    key: 'time_zone',
    value: 'America/Chicago',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: '4',
  ),
  ConfigItem.new(
    key: 'website',
    value: 'http://okclassic.com',
  ),
  ConfigItem.new(
    key: 'paypal_client_id',
    value: 'sb',
  ),
  ConfigItem.new(
    key: 'email_in_dev',
    value: 'false',
  ),
  ConfigItem.new(
    key: 'display_capacity',
    value: 'false',
  ),
]

okc.contacts += [
  Contact.new(
    name: 'David Barz',
    email: 'okclassic2022@yahoo.com',
    role: :director,
  ),
  Contact.new(
    name: 'Donnie Chance',
    email: 'donniechance66@gmail.com',
    role: :secretary,
    notify_on_registration: true,
  ),
  Contact.new(
    name: 'George Noe',
    email: 'glnoe82@gmail.com',
    role: :treasurer,
    notify_on_payment: true,
  ),
]

okc.purchasable_items += [
  PurchasableItem.new(
    category: :ledger,
    determination: :entry_fee,
    name: 'Tournament entry fee',
    user_selectable: false,
    value: 110,
  ),
  PurchasableItem.new(
    category: :ledger,
    determination: :late_fee,
    name: 'Late registration fee',
    user_selectable: false,
    value: 10,
    configuration: {
      applies_at: '2023-03-28T00:00:00-05:00',
    },
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    name: 'Friday night 9-pin No-tap',
    user_selectable: true,
    value: 25,
    configuration: {
      order: 1,
    }
  ),
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
      order: 2,
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
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    name: 'Mystery Score',
    user_selectable: true,
    value: 20,
    configuration: {
      order: 7,
    }
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    name: 'Best 3 Across 9',
    user_selectable: true,
    value: 25,
    configuration: {
      order: 8,
    }
  ),
  PurchasableItem.new(
    category: :bowling,
    determination: :single_use,
    refinement: :division,
    name: 'Scratch Masters',
    user_selectable: true,
    value: 50,
    configuration: {
      division: 'A',
      note: '216+',
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
      note: '201-215',
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
      note: '186-200',
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
      note: '160-185',
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
  #   value: 40,
  # ),
  PurchasableItem.new(
    category: :product,
    determination: :multi_use,
    refinement: :denomination,
    name: 'Early Bird Raffle Ticket Pack',
    user_selectable: true,
    value: 60,
    configuration: {
      denomination: '500 tickets',
      note: '$80 at the tournament',
      order: 1,
    },
  ),
]

eff = ExtendedFormField.find_by(name: 'pronouns')
okc.additional_questions << AdditionalQuestion.new(
  extended_form_field: eff,
  validation_rules: eff.validation_rules,
  order: 1,
  )
eff = ExtendedFormField.find_by(name: 'comment')
okc.additional_questions << AdditionalQuestion.new(
  extended_form_field: eff,
  validation_rules: eff.validation_rules,
  order: 2,
)
