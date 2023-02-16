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
require 'rails_helper'

RSpec.describe Purchase, type: :model do
  let(:tournament) { create :tournament }
  let(:bowler) { create(:bowler, tournament: tournament) }
  let(:purchasable_item) { create :purchasable_item, :entry_fee, tournament: tournament }

  let(:paid_at) { nil }
  let(:voided_at) { nil }
  let(:purchase) do
    Purchase.new(
      bowler: bowler,
      purchasable_item: purchasable_item,
      paid_at: paid_at,
      voided_at: voided_at
    )
  end

  describe 'validations' do
    subject { purchase.valid? }

    context 'unpaid and not voided' do
      it { is_expected.to be_truthy }
    end

    context 'paid but not voided' do
      let(:paid_at) { 1.week.ago }

      it { is_expected.to be_truthy }
    end

    context 'voided but not paid' do
      let(:voided_at) { 1.week.ago }

      it { is_expected.to be_truthy }
    end

    context 'paid and voided cannot both be set' do
      let(:paid_at) { 2.weeks.ago }
      let(:voided_at) { 1.week.ago }

      it { is_expected.to be_falsey }
    end
  end
end
