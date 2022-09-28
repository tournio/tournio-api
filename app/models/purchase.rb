# frozen_string_literal: true

# == Schema Information
#
# Table name: purchases
#
#  id                  :bigint           not null, primary key
#  amount              :integer          default(0)
#  identifier          :string           not null
#  paid_at             :datetime
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

class Purchase < ApplicationRecord
  belongs_to :bowler
  belongs_to :purchasable_item
  belongs_to :external_payment, optional: true, dependent: :destroy

  delegate :name, :value, :configuration, :determination, :category, :refinement, to: :purchasable_item

  before_create :generate_identifier, :get_value_from_item

  scope :unpaid, -> { where(paid_at: nil) }
  scope :paid, -> { where.not(paid_at: nil) }
  scope :bowling, -> { joins(:purchasable_item).where(purchasable_item: {category: :bowling}) }
  scope :single_use, -> { joins(:purchasable_item).where(purchasable_item: {determination: :single_use}) }
  scope :entry_fee, -> { joins(:purchasable_item).where(purchasable_item: {determination: :entry_fee}) }
  scope :ledger, -> { joins(:purchasable_item).where(purchasable_items: {category: :ledger}) }
  scope :event, -> { joins(:purchasable_item).where(purchasable_item: {determination: :event}) }
  scope :bundle_discount, -> { joins(:purchasable_item).where(purchasable_item: {category: :ledger, determination: :bundle_discount}) }
  scope :early_discount, -> { joins(:purchasable_item).where(purchasable_item: {category: :ledger, determination: :early_discount}) }
  scope :late_fee, -> { joins(:purchasable_item).where(purchasable_item: {category: :ledger, determination: :late_fee})}
  scope :event_linked, -> { joins(:purchasable_item).where(purchasable_item: {refinement: :event_linked})}

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end

  def get_value_from_item
    self.amount = purchasable_item.value
  end
end
