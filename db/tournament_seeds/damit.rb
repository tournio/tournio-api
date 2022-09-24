# frozen_string_literal: true

tournament = Tournament.create!(
  name: 'Dallas Area Masters Invitational Tournament',
  year: 2023,
  start_date: '2023-09-25',
  end_date: '2023-09-26',
  abbreviation: 'dagnabit',
  entry_deadline: '2023-09-20T00:00:00-05:00',
  location: 'Plano, TX',
  timezone: 'America/Chicago',
)

tournament.config_items += [
  ConfigItem.new(
    key: 'website',
    value: 'https://www.facebook.com/Damitbowling',
  ),
  ConfigItem.new(
    key: 'display_capacity',
    value: 'false',
  ),
  ConfigItem.new(
    key: 'email_in_dev',
    value: 'false',
  ),
]

tournament.contacts << Contact.new(
  name: 'Steven Hull',
  email: 'damitdirectors@gmail.com',
  role: :director,
  notify_on_registration: true,
  notify_on_payment: true,
  notification_preference: :daily_summary,
)
