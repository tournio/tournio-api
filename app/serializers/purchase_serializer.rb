# frozen_string_literal: true

# == Schema Information
#
# Table name: purchases
#
#  id                  :bigint           not null, primary key
#  amount              :integer          default(0)
#  identifier          :string           not null
#  paid_at             :datetime
#  void_reason         :string
#  voided_at           :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  bowler_id           :bigint
#  external_payment_id :bigint
#  purchasable_item_id :bigint
#
# Indexes
#
#  index_purchases_on_bowler_id            (bowler_id)
#  index_purchases_on_external_payment_id  (external_payment_id)
#  index_purchases_on_identifier           (identifier)
#  index_purchases_on_purchasable_item_id  (purchasable_item_id)
#
class PurchaseSerializer < JsonSerializer
  attributes :identifier,
    :amount,
    :paid_at,
    :voided_at,
    :created_at

  one :purchasable_item, resource: PurchasableItemSerializer
  one :external_payment, resource: ExternalPaymentSerializer
end
