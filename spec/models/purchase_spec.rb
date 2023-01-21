# frozen_string_literal: true

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
