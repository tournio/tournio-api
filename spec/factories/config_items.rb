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

FactoryBot.define do
  factory :config_item do
    trait :email_in_dev do
      key { 'email_in_dev'}
      value { 'true' }
    end
    trait :display_capacity do
      key { 'display_capacity'}
      value { 'true' }
    end
    trait :website do
      key { 'website'}
      value { 'www.igbo.org' }
    end
  end
end
