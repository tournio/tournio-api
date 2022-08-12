# frozen_string_literal: true

playground = Tournament.create!(
  name: 'Birthday Bash',
  year: 2022,
  start_date: '2022-12-28',
)

playground.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'Atlanta, GA',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-12-20T23:59:59-05:00',
  ),
  ConfigItem.new(
    key: 'time_zone',
    value: 'America/New_York',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: 4,
  ),
  ConfigItem.new(
    key: 'website',
    value: 'http://www.stebleton.net',
  ),
  ConfigItem.new(
    key: 'email_in_dev',
    value: 'false',
  ),
]

playground.contacts << Contact.new(
  name: 'Kylie Minogue',
  email: 'director@playground.org',
  role: :director,
)
playground.contacts << Contact.new(
  name: 'Dua Lipa',
  email: 'architect@playground.org',
  role: :treasurer,
)
playground.contacts << Contact.new(
  name: 'Tom Aspaul',
  email: 'musicman@playground.org',
  role: :secretary,
)
