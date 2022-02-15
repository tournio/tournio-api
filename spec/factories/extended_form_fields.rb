# == Schema Information
#
# Table name: extended_form_fields
#
#  id                  :bigint           not null, primary key
#  helper_text         :string
#  helper_url          :string
#  html_element_config :jsonb
#  html_element_type   :string           default("input")
#  label               :string           not null
#  name                :string           not null
#  validation_rules    :jsonb
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
FactoryBot.define do
  factory :extended_form_field do
    name { "an_extended_form_field" }
    label { "An Extended Form Field" }
    html_element_type { 'input' }
    html_element_config { { type: 'text', value: '' } }
    validation_rules { { required: false } }
  end

  trait :comment do
    name { 'comment' }
  end

  trait :standings_link do
    name { 'standings_link' }
    html_element_config do
      {
        type: 'url',
        value: ''
      }
    end
  end

  trait :pronouns do
    name { 'pronouns' }
    html_element_type { 'select' }
    html_element_config do
      {
        options: [
          {
            value: '',
            label: '-- Indicate your pronouns',
          },
          {
            value: 'he/him',
            label: 'he/him',
          },
          {
            value: 'she/her',
            label: 'she/her',
          },
          {
            value: 'they/them',
            label: 'they/them',
          },
          {
            value: 'something else',
            label: 'something else (let us know!)',
          },
        ],
        value: '',
      }
    end
  end
end
