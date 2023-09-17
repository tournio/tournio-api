# frozen_string_literal: true

require "rails_helper"

RSpec.describe AddPurchasableItemToBowlerJob, type: :job do
  describe '#perform' do
    let(:tournament) { create :tournament }
    let(:pi) { create :purchasable_item, :raffle_bundle, tournament: tournament }
    let(:bowler) { create :bowler, tournament: tournament }

    subject { described_class.new.perform(bowler.id, pi.id) }

    it 'creates a Purchase' do
      expect { subject }.to change(Purchase, :count).by(1)
    end

    it 'creates a LedgerEntry' do
      expect { subject }.to change(LedgerEntry, :count).by(1)
    end

    it 'marks the created LedgerEntry with automatic as the source' do
      subject
      le = LedgerEntry.last
      expect(le.automatic?).to be_truthy
    end

    it 'indicates the item name in the identifier' do
      subject
      le = LedgerEntry.last
      expect(le.identifier).to eq(pi.name)
    end

    it 'marks the ledger entry as a debit' do
      subject
      le = LedgerEntry.last
      expect(le.debit).to eq(pi.value)
    end

    context 'when the purchase is not the first' do
      before do
        create :purchase, bowler: bowler, purchasable_item: pi, amount: pi.value, paid_at: 3.days.ago
      end

      it 'does not raise a one-time-purchase error' do
        expect { subject }.not_to raise_error
      end

      context 'but the item is a one-timer' do
        let(:pi) { create :purchasable_item, :late_fee, tournament: tournament }

        it 'raises a one-time-purchase error' do
          expect { subject }.to raise_error AddPurchasableItemToBowlerJob::OneTimePurchaseOnlyError
        end
      end
    end

    context 'an unrecognized item id' do
      # this will be for some other tournament
      let(:pi) { create :purchasable_item, :banquet_entry }

      it 'raises a not-found error' do
        expect { subject }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
