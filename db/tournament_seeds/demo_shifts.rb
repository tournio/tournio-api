# frozen_string_literal: true

tournament = Tournament.create!(
  name: 'Demo Tournament With Shifts',
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
    key: 'timezone',
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
  name: 'Dorothy Gale',
  email: 'secretary@example.org',
  role: :secretary,
)
tournament.contacts << Contact.new(
  name: 'Stevie Nicks',
  email: 'treasurer@example.org',
  role: :treasurer,
)

tournament.shifts += [
  Shift.new(
    capacity: 24,
    name: 'Early',
    description: 'Singles on Friday 5-9pm, Doubles/Team on Saturday 9am-3pm',
    display_order: 1,
  ),
  Shift.new(
    capacity: 24,
    name: 'Late',
    description: 'Singles on Friday 9:30pm-midnight, Doubles/Team Saturday 4-10pm',
    display_order: 2,
  ),
]
