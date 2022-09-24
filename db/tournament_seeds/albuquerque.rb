# frozen_string_literal: true

tournament = Tournament.create!(
  name: 'The Albuquerque Roadrunner Tournament',
  year: 2022,
  start_date: '2022-09-16',
  identifier: 'tart-2022',
)

tournament.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'Albuquerque, NM',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-08-24T23:59:59-05:00',
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
    value: 'http://beepbeepbowl.org/',
  ),
  ConfigItem.new(
    key: 'paypal_client_id',
    value: 'sb',
  ),
  ConfigItem.new(
    key: 'display_capacity',
    value: 'false',
  ),
]

if (Rails.env.development?)
  tournament.config_items << ConfigItem.new(key: 'email_in_dev', value: 'false')
end

tournament.contacts << Contact.new(
  name: 'Director Person',
  email: 'director@beepbeepbowl.org',
  role: :director,
)
tournament.contacts << Contact.new(
  name: 'Secretary Person',
  email: 'secretary@beepbeepbowl.org',
  role: :secretary,
  notify_on_registration: true,
  notification_preference: :daily_summary,
)
tournament.contacts << Contact.new(
  name: 'Treasurer Person',
  email: 'treasurer@beepbeepbowl.org',
  role: :treasurer,
  notify_on_payment: true,
  notification_preference: :daily_summary,
)
