# frozen_string_literal: true

# == Schema Information
#
# Table name: config_items
#
#  id            :bigint           not null, primary key
#  key           :string           not null
#  value         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tournament_id :bigint
#
# Indexes
#
#  index_config_items_on_tournament_id_and_key  (tournament_id,key) UNIQUE
#

FactoryBot.define do
  factory :config_item do
    trait :location do
      key   { 'location' }
      value { 'Denver, CO' }
    end

    trait :late_fee_applies_at do
      key { 'late_fee_applies_at' }
      value { '2018-12-28T18:27:00-07:00' }
    end

    trait :entry_deadline do
      key { 'entry_deadline' }
      value { '2018-12-31T23:59:59-07:00' }
    end

    trait :time_zone do
      key { 'time_zone' }
      value { 'America/Denver' }
    end

    trait :paypal_client_id do
      key { 'paypal_client_id' }
      value { 'a-tournament-client-id' }
    end

    trait :email_in_dev do
      key { 'email_in_dev'}
      value { 'true' }
    end
  end
end
