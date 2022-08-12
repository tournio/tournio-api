# frozen_string_literal: true

playground = Tournament.create!(
  name: 'Playground Tournament',
  year: 2022,
  start_date: '2022-11-03',
)

playground.config_items += [
  ConfigItem.new(
    key: 'location',
    value: 'Atlanta, GA',
  ),
  ConfigItem.new(
    key: 'entry_deadline',
    value: '2022-10-26T23:59:59-04:00',
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
    value: 'http://www.igbo.org',
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

playground.contacts << Contact.new(
  name: 'Kylie Minogue',
  email: 'director@playground.org',
  role: :director,
)
playground.contacts << Contact.new(
  name: 'Dua Lipa',
  email: 'architect@playground.org',
  role: :secretary,
)
playground.contacts << Contact.new(
  name: 'Tom Aspaul',
  email: 'musicman@playground.org',
  role: :treasurer,
)

eff = ExtendedFormField.find_by(name: 'standings_link')
playground.additional_questions << AdditionalQuestion.new(
  extended_form_field: eff,
  validation_rules: eff.validation_rules,
  order: 2,
)
eff = ExtendedFormField.find_by(name: 'comment')
playground.additional_questions << AdditionalQuestion.new(
  extended_form_field: eff,
  validation_rules: eff.validation_rules,
  order: 3,
)
eff = ExtendedFormField.find_by(name: 'pronouns')
playground.additional_questions << AdditionalQuestion.new(
  extended_form_field: eff,
  validation_rules: eff.validation_rules,
  order: 1,
)
