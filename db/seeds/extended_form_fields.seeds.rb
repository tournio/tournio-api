# frozen_string_literal: true

ExtendedFormField.create(
  name: 'comment',
  label: 'Anything else we should know?',
  html_element_type: 'input',
  html_element_config: { type: 'text', value: '' },
  validation_rules: { required: false },
  helper_text: '',
  helper_url: '',
) unless ExtendedFormField.find_by(name: 'comment').present?

ExtendedFormField.create(
  name: 'standings_link',
  label: 'URL of current league standing sheet',
  html_element_type: 'input',
  html_element_config: { type: 'url', value: '' },
  validation_rules: { required: false },
  helper_text: '',
  helper_url: '',
) unless ExtendedFormField.find_by(name: 'standings_link').present?

ExtendedFormField.create(
  name: 'pronouns',
  label: 'Preferred pronouns',
  html_element_type: 'select',
  html_element_config: {
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
  },
  validation_rules: { required: false },
  helper_text: '',
  helper_url: '',
) unless ExtendedFormField.find_by(name: 'pronouns').present?

ExtendedFormField.create(
  name: 'entering_average',
  label: 'Entering average',
  html_element_type: 'input',
  html_element_config: {
    type: 'number',
    value: '',
  },
  validation_rules: {
    min: 0,
    max: 300,
  },
  helper_text: 'See tournament rules for details',
) unless ExtendedFormField.find_by(name: 'entering_average').present?

ExtendedFormField.create(
  name: 'shirt_size',
  label: 'Shirt size',
  html_element_type: 'select',
  html_element_config: {
    options: [
      {
        value: '',
        label: '-- Indicate your shirt size',
      },
      {
        value: "men's xs",
        label: "Men's XS",
      },
      {
        value: "men's s",
        label: "Men's S",
      },
      {
        value: "men's m",
        label: "Men's M",
      },
      {
        value: "men's l",
        label: "Men's L",
      },
      {
        value: "men's xl",
        label: "Men's XL",
      },
      {
        value: "men's 2xl",
        label: "Men's 2XL",
      },
      {
        value: "men's 3xl",
        label: "Men's 3XL",
      },
      {
        value: "men's 4xl",
        label: "Men's 4XL",
      },
      {
        value: "women's xs",
        label: "Women's XS",
      },
      {
        value: "women's s",
        label: "Women's S",
      },
      {
        value: "women's m",
        label: "Women's M",
      },
      {
        value: "women's l",
        label: "Women's L",
      },
      {
        value: "women's xl",
        label: "Women's XL",
      },
      {
        value: "women's 2xl",
        label: "Women's 2XL",
      },
      {
        value: "women's 3xl",
        label: "Women's 3XL",
      },
      {
        value: "women's 4xl",
        label: "Women's 4XL",
      },
      {
        value: "other",
        label: "Other (please let us know!)",
      },
    ],
    value: '',
  },
  validation_rules: { required: false },
  helper_text: '',
  helper_url: '',
) unless ExtendedFormField.find_by(name: 'shirt_size').present?

ExtendedFormField.create(
  name: 'shirt_size_unisex',
  label: 'Shirt size (unisex)',
  html_element_type: 'select',
  html_element_config: {
    options: [
      {
        value: '',
        label: '-- Indicate your shirt size',
      },
      {
        value: "xs",
        label: "XS",
      },
      {
        value: "s",
        label: "S",
      },
      {
        value: "m",
        label: "M",
      },
      {
        value: "l",
        label: "L",
      },
      {
        value: "xl",
        label: "XL",
      },
      {
        value: "2xl",
        label: "2XL",
      },
      {
        value: "3xl",
        label: "3XL",
      },
      {
        value: "4xl",
        label: "4XL",
      },
      {
        value: "other",
        label: "Other (please let us know!)",
      },
    ],
    value: '',
  },
  validation_rules: { required: false },
  helper_text: '',
  helper_url: '',
) unless ExtendedFormField.find_by(name: 'shirt_size_unisex').present?

ExtendedFormField.create(
  name: 'dietary',
  label: 'Any dietary restrictions we should know about?',
  html_element_type: 'input',
  html_element_config: { type: 'text', value: '' },
  validation_rules: { required: false },
  helper_text: '(vegetarian / vegan / allergies / etc.)',
  helper_url: '',
) unless ExtendedFormField.find_by(name: 'dietary').present?

ExtendedFormField.create(
  name: 'staying_at_host_hotel',
  label: 'Do you plan to stay at the host hotel?',
  html_element_type: 'checkbox',
  html_element_config: { label: 'Yes', value: 'no' },
  validation_rules: { required: false },
  helper_text: '',
  helper_url: '',
) unless ExtendedFormField.find_by(name: 'staying_at_host_hotel').present?

ExtendedFormField.create(
  name: 'volunteer_while_not_bowling',
  label: "'Are you able to volunteer when you're not bowling?'",
  html_element_type: 'checkbox',
  html_element_config: { label: 'Yes', value: 'no' },
  validation_rules: { required: false },
  helper_text: '',
  helper_url: '',
) unless ExtendedFormField.find_by(name: 'staying_at_host_hotel').present?

ExtendedFormField.create(
  name: 'birth_year',
  label: 'Birth year',
  html_element_type: 'input',
  html_element_config: { type: 'number', value: '', placeholder: 'YYYY' },
  validation_rules: { required: false, min: 0, max: 2050 },
  helper_text: '',
  helper_url: '',
) unless ExtendedFormField.find_by(name: 'birth_year').present?

ExtendedFormField.create(
  name: 'igbo_rep',
  label: "Are you an IGBO Representative for a league or tournament?",
  html_element_type: 'checkbox',
  html_element_config: { label: 'Yes', value: 'no' },
  validation_rules: { required: false },
  helper_text: '',
  helper_url: '',
) unless ExtendedFormField.find_by(name: 'igbo_rep').present?

ExtendedFormField.create(
  name: 'friday_team_event',
  label: "Would you be able to bowl the Team Event on Friday at 8pm?",
  html_element_type: 'checkbox',
  html_element_config: { label: 'Yes', value: 'no' },
  validation_rules: { required: false },
  helper_text: '',
  helper_url: '',
) unless ExtendedFormField.find_by(name: 'friday_team_event').present?

ExtendedFormField.create(
  name: 'has_free_entry',
  label: "I have a free entry",
  html_element_type: 'checkbox',
  html_element_config: { label: '', value: 'no' },
  validation_rules: { required: false },
  helper_text: '',
  helper_url: '',
) unless ExtendedFormField.find_by(name: 'has_free_entry').present?

ExtendedFormField.create(
  name: 'igbo_tad_average',
  label: 'IGBO TAD Average',
  html_element_type: 'input',
  html_element_config: {
    type: 'number',
    value: '',
  },
  validation_rules: {
    min: 0,
    max: 300,
  },
  helper_text: 'See tournament rules for details',
) unless ExtendedFormField.find_by(name: 'igbo_tad_average').present?
