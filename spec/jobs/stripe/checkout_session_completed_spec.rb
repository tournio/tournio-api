require "rails_helper"

RSpec.describe Stripe::CheckoutSessionCompleted, type: :job do
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
    # So we can determine how the method goes by populating the event's
    # line_items attribute
    #
    # For a single line item, these are the properties we're interested in:
    #   {
    #     quantity: 1,
    #     price: {
    #       id: "price_1LHWKBRIPoTBJbS2aG8aEqQ6",
    #       product: "prod_LzVKbov8aOmsGL",
    #     },
    #   },
    #
    # The combination of price_id and product_id (both Stripe-generated
    # identifiers) is enough to find an associated PurchasableItem.
    # The Stripe objects Price and Product are created at the time of
    # PurchasableItem creation.
    #
    # We rely on our price/value/amount data, not the data in Stripe's
    # API responses. (If there's ever a discrepancy, that's our problem.)

    let(:event_handler) { described_class.new }

    subject { event_handler.handle_event }

    before do
      allow(event_handler).to receive(:event).and_return(mock_event)
      allow(event_handler).to receive(:retrieve_stripe_object).and_return(mock_checkout_session)
      Sidekiq::Job.clear_all
    end

    context 'a standard tournament' do
      let(:tournament) { create :tournament, :active, :one_shift }
      let(:bowler) { create :bowler, tournament: tournament }
      before do
        create :stripe_checkout_session,
          bowler: bowler,
          checkout_session_id: mock_checkout_session[:id]
      end

      context 'regular registration' do
        let(:entry_fee_amount) { 117 }
        let!(:entry_fee_item) do
          create(:purchasable_item,
            :entry_fee,
            :with_stripe_product,
            value: entry_fee_amount,
            tournament: tournament
          )
        end

        before do
          create(:purchase, bowler: bowler, purchasable_item: entry_fee_item, amount: entry_fee_amount)
        end

        context 'with an entry fee' do
          let(:mock_checkout_session) do
            object_for_items([
              {
                item: entry_fee_item,
                quantity: 1,
              },
            ])
          end

          it_behaves_like 'a Stripe event handler'

          it 'associates the ExternalPayment to the entry-fee Purchase' do
            subject
            expect(bowler.purchases.entry_fee.first.external_payment_id).to eq(ExternalPayment.last.id)
          end

          it 'marks the entry-fee purchase as paid' do
            subject
            expect(bowler.purchases.entry_fee.first.paid_at).not_to be_nil
          end

          it 'has the full payment amount on the LedgerEntry' do
            subject
            expect(LedgerEntry.last.credit).to eq(entry_fee_amount)
          end

          context 'and some optional items' do
            let!(:item_1) do
              create(:purchasable_item,
                :scratch_competition,
                :with_stripe_product,
                tournament: tournament
              )
            end

            let!(:item_2) do
              create(:purchasable_item,
                :optional_event,
                :with_stripe_product,
                value: 21,
                tournament: tournament
              )
            end

            let(:mock_checkout_session) do
              object_for_items([
                {
                  item: entry_fee_item,
                  quantity: 1,
                },
                {
                  item: item_1,
                  quantity: 1,
                },
                {
                  item: item_2,
                  quantity: 1,
                },
              ])
            end

            let(:expected_total) { entry_fee_item.value + item_1.value + item_2.value }

            it_behaves_like 'a Stripe event handler'

            it 'creates a Purchase for each optional item' do
              expect { subject }.to change { bowler.purchases.count }.by(2)
            end

            it 'creates a ledger entry for each Purchase' do
              expect { subject }.to change { bowler.ledger_entries.purchase.count }.by(2)
            end

            it 'has the full payment amount on the LedgerEntry' do
              subject
              expect(bowler.ledger_entries.stripe.take.credit).to eq(expected_total)
            end
          end
        end
      end

      context 'error conditions' do

      end
    end

    context 'a tournament with event selection', pending: true do

    end
  end
end
