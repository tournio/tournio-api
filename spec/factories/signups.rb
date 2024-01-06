# frozen_string_literal: true

# == Schema Information
#
# Table name: signups
#
#  id                  :bigint           not null, primary key
#  aasm_state          :string           default("initial")
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  bowler_id           :bigint
#  purchasable_item_id :bigint
#
# Indexes
#
#  index_signups_on_bowler_id            (bowler_id)
#  index_signups_on_purchasable_item_id  (purchasable_item_id)
#
FactoryBot.define do
  factory :signup do
    association :bowler, strategy: :build
    association :purchasable_item, strategy: :build

    trait :requested do
      aasm_state { :requested }
    end

    trait :paid do
      aasm_state { :paid }
    end
  end
end
