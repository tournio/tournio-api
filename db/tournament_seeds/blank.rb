# frozen_string_literal: true

tournament = Tournament.create!(
  name: 'New Year, New Me',
  year: 2023,
  start_date: '2023-01-01',
  identifier: 'new-year-new-me-2023',
)

tournament.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'Anywhere, USA',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-12-25T23:59:59-04:00',
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
    key: 'email_in_dev',
    value: 'false',
  ),
  ConfigItem.new(
    key: 'display_capacity',
    value: 'false',
  ),
]
