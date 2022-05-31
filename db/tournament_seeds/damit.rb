# frozen_string_literal: true

tournament = Tournament.create!(
  name: 'Dallas Area Masters Invitational Tournament - DEV',
  year: 2022,
  start_date: '2022-09-24',
  identifier: 'damit-2022',
)

tournament.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'Plano, TX',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-09-18T12:00:00-05:00',
  ),
  ConfigItem.new(
    key: 'time_zone',
    value: 'America/Chicago',
  ),
  ConfigItem.new(
    key: 'image_path',
    value: '/images/damit.png',
  ),
  ConfigItem.new(
    key: 'website',
    value: 'https://www.facebook.com/Damitbowling',
  ),
  ConfigItem.new(
    key: 'paypal_client_id',
    value: 'sb',
  ),
  ConfigItem.new(
    key: 'display_capacity',
    value: 'false',
  ),
  ConfigItem.new(
    key: 'event_selection',
    value: 'true',
  ),
  ConfigItem.new(
    key: 'registration',
    value: 'individual,partner',
  ),
]

if (Rails.env.development?)
  tournament.config_items << ConfigItem.new(key: 'email_in_dev', value: 'false')
end

tournament.contacts << Contact.new(
  name: 'Steven Hull',
  email: 'damitdirectors@gmail.com',
  role: :director,
  notify_on_registration: true,
  notify_on_payment: true,
  notification_preference: :daily_summary,
)
