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
class SignupSerializer < PurchasableItemSerializer
  attribute :status do |item|
    if params[:signup].present?
      params[:signup].aasm_state
    end
  end
end
