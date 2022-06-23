# frozen_string_literal: true

ExtendedFormField.create(
  name: 'comment',
  label: 'Anything else we should know?',
  html_element_type: 'input',
  html_element_config: { type: 'text', value: '' },
  validation_rules: { required: false },
  helper_text: '',
  helper_url: '',
)

ExtendedFormField.create(
  name: 'standings_link',
  label: 'URL of current league standing sheet',
  html_element_type: 'input',
  html_element_config: { type: 'url', value: '' },
  validation_rules: { required: false },
  helper_text: '',
  helper_url: '',
)

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
)

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
)

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
        value: "men's xxl",
        label: "Men's XXL",
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
        value: "women's xxl",
        label: "Women's XXL",
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
)
