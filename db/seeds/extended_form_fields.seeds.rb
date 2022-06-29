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
