# frozen_string_literal: true

tournament = Tournament.create!(
  name: 'Blank Tournament',
  year: 2022,
  start_date: '2022-12-28',
)

tournament.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'Anywhere, USA',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-12-16T23:59:59-04:00',
  ),
  ConfigItem.new(
    key: 'time_zone',
    value: 'America/Denver',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: 4,
  ),
  ConfigItem.new(
    key: 'website',
    value: 'http://www.igbo-reg.com',
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
  name: 'Kylie Minogue',
  email: 'director@example.org',
  role: :director,
)
tournament.contacts << Contact.new(
  name: 'Dua Lipa',
  email: 'architect@example.org',
  role: :secretary,
)
tournament.contacts << Contact.new(
  name: 'Stevie Nicks',
  email: 'treasurer@example.org',
  role: :treasurer,
)

# tournament.purchasable_items += [
  # PurchasableItem.new(
  #   category: :ledger,
  #   determination: :entry_fee,
  #   name: 'Tournament entry fee',
  #   user_selectable: false,
  #   value: 119,
  # ),
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
  # PurchasableItem.new(
  #   category: :ledger,
  #   determination: :late_fee,
  #   name: 'Late registration fee',
  #   user_selectable: false,
  #   value: 11,
  #   configuration: {
  #     applies_at: '2022-09-01T00:00:00-04:00',
  #   },
  # ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   refinement: :division,
  #   name: 'Scratch Masters',
  #   user_selectable: true,
  #   value: 50,
  #   configuration: {
  #     division: 'E',
  #     note: '0-149',
  #   },
  # ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   refinement: :division,
  #   name: 'Scratch Masters',
  #   user_selectable: true,
  #   value: 50,
  #   configuration: {
  #     division: 'D',
  #     note: '150-169',
  #   },
  # ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   refinement: :division,
  #   name: 'Scratch Masters',
  #   user_selectable: true,
  #   value: 50,
  #   configuration: {
  #     division: 'C',
  #     note: '170-189',
  #   },
  # ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   refinement: :division,
  #   name: 'Scratch Masters',
  #   user_selectable: true,
  #   value: 60,
  #   configuration: {
  #     division: 'B',
  #     note: '190-209',
  #   },
  # ),
  # PurchasableItem.new(
  #   category: :bowling,
  #   determination: :single_use,
  #   refinement: :division,
  #   name: 'Scratch Masters',
  #   user_selectable: true,
  #   value: 60,
  #   configuration: {
  #     division: 'A',
  #     note: '210+',
  #   },
  # ),
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
# ]
