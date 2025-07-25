# frozen_string_literal: true

# == Schema Information
#
# Table name: config_items
#
#  id            :bigint           not null, primary key
#  key           :string           not null
#  label         :string
#  value         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint
#
# Indexes
#
#  index_config_items_on_tournament_id_and_key  (tournament_id,key) UNIQUE
#

class ConfigItem < ApplicationRecord
  module Keys
    ACCEPT_PAYMENTS = 'accept_payments'
    BOWLER_FORM_FIELDS = 'bowler_form_fields'
    DISPLAY_CAPACITY = 'display_capacity'
    EMAIL_IN_DEV = 'email_in_dev'
    ENABLE_FREE_ENTRIES = 'enable_free_entries'
    ENABLE_UNPAID_SIGNUPS = 'enable_unpaid_signups'
    PUBLICLY_LISTED = 'publicly_listed'
    REGISTRATION_WITHOUT_PAYMENTS = 'registration_without_payments'
    SKIP_STRIPE = 'skip_stripe'
    TEAM_SIZE = 'team_size'
    TOURNAMENT_TYPE = 'tournament_type'
    WEBSITE = 'website'
    PAYMENT_PAGE = 'payment_page'
  end

  module Labels
    ACCEPT_PAYMENTS = 'Accept Payments'
    BOWLER_FORM_FIELDS = 'Bowler Form Fields'
    DISPLAY_CAPACITY = 'Display Capacity'
    EMAIL_IN_DEV = '[dev] Send Emails'
    ENABLE_FREE_ENTRIES = 'Accept Free Entry Codes from Bowlers'
    ENABLE_UNPAID_SIGNUPS = 'Allow Unpaid Signups for Optional Events'
    PUBLICLY_LISTED = 'Publicly Listed'
    REGISTRATION_WITHOUT_PAYMENTS = 'Registration Without Payments'
    SKIP_STRIPE = 'Skip Stripe'
    TEAM_SIZE = 'Team Size'
    TOURNAMENT_TYPE = 'Tournament Type'
    WEBSITE = 'Website URL'
    PAYMENT_PAGE = 'Payment Page'
  end

  private_constant :Labels
  # private_class_method :new

  belongs_to :tournament
  default_scope { order(key: :asc) }

  def self.gimme(key_sym:, initial_value: 'true')
    new(
      key: Keys.const_get(key_sym),
      value: initial_value,
      label: Labels.const_get(key_sym),
    )
  end
end
