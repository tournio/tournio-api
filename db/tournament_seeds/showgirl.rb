# frozen_string_literal: true

t = Tournament.create!(
  name: 'Las Vegas Showgirl Tournament',
  year: 2022,
  start_date: '2022-09-02',
)

t.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'Las Vegas, NV',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2020-08-15T23:59:59-07:00',
  ),
  ConfigItem.new(
    key: 'time_zone',
    value: 'America/Los_Angeles',
  ),
  ConfigItem.new(
    key: 'image_path',
    value: '/images/showgirl.jpg',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: 4,
  ),
  ConfigItem.new(
    key: 'website',
    value: 'http://lvshowgirl.net/',
  ),
  ConfigItem.new(
    key: 'email_in_dev',
    value: 'false',
  ),
]

t.contacts += [
  Contact.new(
    name: 'Randy Ulrich',
    email: 'codirector1@lvshowgirl.net',
    role: :director,
  ),
  Contact.new(
    name: 'Vanessa Quigley',
    email: 'treasurer@lvshowgirl.net',
    role: :treasurer,
    notify_on_payment: true,
  ),
  Contact.new(
    name: 'Mikey Bridges',
    email: 'secretary@lvshowgirl.net',
    role: :secretary,
    notify_on_registration: true,
  ),
]
