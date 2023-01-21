# frozen_string_literal: true

require "rails_helper"

RSpec.describe VoidPurchaseJob, type: :job do
  describe '#perform' do
    let(:tournament) { create :tournament }
    let(:pi) { create :purchasable_item, :early_discount, tournament: tournament }
    let(:bowler) { create :bowler, tournament: tournament }
    let(:paid_at) { nil }
    let(:voided_at) { nil }

    let(:purchase) do
      create :purchase,
        purchasable_item: pi,
        bowler:bowler,
        paid_at: paid_at,
        voided_at: voided_at
    end

    let(:why) { 'a really good reason' }

    subject { described_class.new.perform(purchase.id, why) }

    it 'updates the voided_at attribute' do
      subject
      expect(purchase.reload.voided_at).not_to be_nil
    end

    it 'creates a ledger entry' do
      expect { subject }.to change(LedgerEntry, :count).by(1)
    end

    it 'marks the created LedgerEntry with void as the source' do
      subject
      le = LedgerEntry.last
      expect(le.void?).to be_truthy
    end

    context 'when the purchase is paid' do
      let(:paid_at) { 2.weeks.ago }

      it 'does not update the voided_at attribute' do
        expect { subject }.not_to change(purchase, :voided_at)
      end

      it 'does not create a ledger entry' do
        expect { subject }.not_to change(LedgerEntry, :count)
      end
    end

    context 'when the purchase is already voided' do
      let(:voided_at) { 2.weeks.ago }

      it 'does not update the voided_at attribute' do
        expect { subject }.not_to change(purchase, :voided_at)
      end

      it 'does not create a ledger entry' do
        expect { subject }.not_to change(LedgerEntry, :count)
      end
    end
  end
end
