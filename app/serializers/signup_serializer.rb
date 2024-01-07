# frozen_string_literal: true

# == Schema Information
#
# Table name: signups
#
#  id                  :bigint           not null, primary key
#  aasm_state          :string           default("initial")
#  identifier          :string           not null
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
class SignupSerializer < JsonSerializer
  attributes :identifier

  attribute :status, &:aasm_state

  one :purchasable_item, resource: PurchasableItemSerializer
end
