require "rails_helper"

RSpec.describe Stripe::ChargeRefunded, type: :job do
  describe "#perform_async" do
    let(:event_id) { 'evt_anEventIdentifier' }
    let(:stripe_account_id) { 'acct_anAccountIdentifier' }

    subject { described_class.perform_async(event_id, stripe_account_id) }

    it "gets enqueued" do
      expect { subject }.to change(described_class.jobs, :size).by(1)
    end
  end

  describe '#handle_event' do
    # When this method runs, the job's "event" attribute has already been set.
    #
    # the event's object is a charge

    let(:event_handler) { described_class.new }
    let(:charge_identifier) { "ch_test_#{SecureRandom.uuid}" }
    let(:payment_intent_identifier) { "pi_test_#{SecureRandom}" }
    let(:amount_refunded) { 12345 }
    let(:refunded) { true }
    let(:mock_event) do
      {
        id: "evt_test_#{SecureRandom.uuid}",
        object: {
          id: charge_identifier,
          object: 'charge',
          amount_refunded: amount_refunded,
          payment_intent: payment_intent_identifier,
          refunded: refunded,
          status: 'succeeded',
        }
      }
    end
    let(:tournament) { create :tournament }
    let(:bowler) { create :bowler, tournament: tournament }
    let!(:payment_ledger_entry) do
      create :ledger_entry,
        :stripe,
        bowler: bowler,
        credit: 99, # this is different because we don't want to enforce parity
        identifier: payment_intent_identifier # this is how we associate a bowler with the refund
    end

    subject { event_handler.handle_event }

    before do
      allow(event_handler).to receive(:event).and_return(mock_event)
    end

    it_behaves_like 'a Stripe event handler'

    it 'creates a debit LedgerEntry' do
      expect { subject }.to change(LedgerEntry, :count).by(1)
    end

    it 'creates a debit LedgerEntry with the charge identifier' do
      subject
      expect(LedgerEntry.last.identifier).to eq(charge_identifier)
    end

    it 'creates a debit LedgerEntry for the refunded amount' do
      subject
      expect(LedgerEntry.last.credit).to be_zero
      expect(LedgerEntry.last.debit).to eq(amount_refunded / 100)
    end

    it 'creates a debit LedgerEntry on the bowler' do
      expect { subject }.to change(bowler.ledger_entries, :count).by(1)
    end

    it 'notifies the appropriate committee member' do
      
    end

    context 'An unrecognized PaymentIntent identifier' do
      let!(:payment_ledger_entry) do
        create :ledger_entry,
          :stripe,
          bowler: bowler,
          credit: 99, # this is different because we don't want to enforce parity
          identifier: 'some other identifier' # this is how we associate a bowler with the refund
      end

      it 'does not raise record not found' do
        expect { subject }.not_to raise_error
      end

      it 'writes a warning to the log' do
        expect(Rails.logger).to receive(:warn)
        subject
      end
    end

    context 'idempotency' do
      before do
        create :ledger_entry,
          :stripe,
          bowler: bowler,
          debit: 101,
          identifier: charge_identifier
      end

      it 'does not create another one' do
        expect { subject }.not_to change(LedgerEntry, :count)
      end
    end
  end
end
