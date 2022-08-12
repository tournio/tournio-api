# frozen_string_literal: true

tournament = Tournament.create!(
  name: 'Missouri and Kansas Invitational Tournament',
  year: 2022,
  start_date: '2022-07-15',
  identifier: 'makit-2022',
)

tournament.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'Kansas City, MO',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-07-10T23:59:59-05:00',
  ),
  ConfigItem.new(
    key: 'time_zone',
    value: 'America/Chicago',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: 4,
  ),
  ConfigItem.new(
    key: 'website',
    value: 'http://www.makitkc.org',
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

tournament.contacts << Contact.new(
  name: 'Alan Emmons',
  email: 'a_emmons13@hotmail.com',
  role: :director,
)
tournament.contacts << Contact.new(
  name: 'Josh Morgan',
  email: 'joshua.morgan@outlook.com',
  role: :secretary,
  notify_on_registration: true,
  notification_preference: :daily_summary,
)
tournament.contacts << Contact.new(
  name: 'Brian Proctor',
  email: 'proctor_brian@yahoo.com',
  role: :statistician,
  notify_on_registration: true,
  notification_preference: :daily_summary,
)
tournament.contacts << Contact.new(
  name: 'David Hocott',
  email: 'fridaynightclubwpl@gmail.com',
  role: :treasurer,
  notify_on_payment: true,
  notification_preference: :daily_summary,
)

tournament.purchasable_items += [
  PurchasableItem.new(
    category: :ledger,
    determination: :entry_fee,
    name: 'Entry fee',
    user_selectable: false,
    value: 105,
  ),
  # PurchasableItem.new(
  #   category: :ledger,
  #   determination: :early_discount,
  #   name: 'Early registration discount',
  #   user_selectable: false,
  #   value: -19,
  #   configuration: {
  #     valid_until: '2022-07-31T00:00:00-04:00',
  #   },
  # ),
  PurchasableItem.new(
    category: :ledger,
    determination: :late_fee,
    name: 'Late registration fee',
    user_selectable: false,
    value: 10,
    configuration: {
      applies_at: '2022-07-01T00:00:00-05:00',
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
      note: 'up to 159',
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
    value: 30,
    configuration: {
      division: 'B',
      note: '190-205',
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
      division: 'A',
      note: '206+',
    },
  ),
  # PurchasableItem.new(
  #   category: :banquet,
  #   determination: :multi_use,
  #   name: 'Banquet Entry (non-bowler)',
  #   user_selectable: true,
  #   value: 40,
  # ),
  # PurchasableItem.new(
  #   category: :product,
  #   determination: :multi_use,
  #   refinement: :denomination,
  #   name: 'Raffle Ticket Pack',
  #   user_selectable: true,
  #   value: 60,
  #   configuration: {
  #     denomination: '500 tickets',
  #     note: 'Packs will be $80 at the tournament',
  #     order: 1,
  #   },
  # ),
]
