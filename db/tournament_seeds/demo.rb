# frozen_string_literal: true

tournament = Tournament.create!(
  name: 'Demo Tournament',
  year: 2022,
  start_date: '2022-09-23',
)

tournament.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'Anywhere, USA',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-09-09T23:59:59-06:00',
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
    value: 'http://www.tourn.io',
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
  name: 'Dorothy Gale',
  email: 'secretary@example.org',
  role: :secretary,
)
tournament.contacts << Contact.new(
  name: 'Stevie Nicks',
  email: 'treasurer@example.org',
  role: :treasurer,
)

tournament.shifts << Shift.new(
  capacity: 120,
  name: 'Main',
  description: 'Singles on Friday 6-9pm, Doubles/Team Saturday 11am-5pm',
  display_order: 1,
)
