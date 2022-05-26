# frozen_string_literal: true

svit = Tournament.create!(
  name: 'Silicon Valley Invitational Tournament',
  year: 2022,
  start_date: '2022-03-18',
)

svit.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'San Jose, CA',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2020-03-08T23:59:59-05:00',
  ),
  ConfigItem.new(
    key: 'time_zone',
    value: 'America/Los_Angeles',
  ),
  ConfigItem.new(
    key: 'image_path',
    value: '/images/svit.jpg',
  ),
  ConfigItem.new(
    key: 'team_size',
    value: '4',
  ),
  ConfigItem.new(
    key: 'website',
    value: 'http://svitbowl.com/home.html',
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

svit.contacts += [
  Contact.new(
    name: 'SVIT Director',
    email: 'svit-director@igbo-reg.com',
    notes: 'Director',
  ),
  Contact.new(
    name: 'Secretary',
    email: 'svit-secretary@igbo-reg.com',
    notes: 'Secretary',
  ),
  Contact.new(
    name: 'Treasurer',
    email: 'svit-moneys@igbo-reg.com',
    notes: 'Treasurer',
  ),
  Contact.new(
    name: 'IGBO Representative',
    email: 'svit-igbo@igbo-reg.com',
    notes: 'IGBO Rep',
  ),
]
