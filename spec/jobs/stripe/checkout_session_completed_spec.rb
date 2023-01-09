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
    # The Stripe objects Price and Product are created at the time of
    # PurchasableItem creation, so the combination of price_id and product_id
    # (both Stripe-generated identifiers) is enough to find an associated
    # PurchasableItem.
    #
    # We rely on our price/value/amount data, not the data in Stripe's
    # API responses. (If there's ever a discrepancy, that's our problem to fix.)

    let(:event_handler) { described_class.new }
    let(:bowler) { create :bowler, tournament: tournament }
    let(:mock_checkout_session) { object_for_items([]) }

    subject { event_handler.handle_event }

    before do
      allow(event_handler).to receive(:event).and_return(mock_event)
      allow(event_handler).to receive(:retrieve_stripe_object).and_return(mock_checkout_session)
    end

    context 'a standard tournament' do
      let(:tournament) { create :tournament, :active, :one_shift }

      before do
        create :stripe_checkout_session,
          bowler: bowler,
          identifier: mock_checkout_session[:id]
      end

      it 'marks the checkout session as completed' do
        subject
        sesh = bowler.stripe_checkout_sessions.last
        expect(sesh.completed?).to be_truthy
      end

      it 'correctly populates the StripePaymentIntent identifier' do
        subject
        sesh = bowler.stripe_checkout_sessions.last
        pi_identifier = mock_checkout_session[:payment_intent]
        expect(sesh.payment_intent_identifier).to eq(pi_identifier)
      end

      context 'with an entry fee' do
        let(:entry_fee_amount) { 117 }
        let(:entry_fee_item) do
          create(:purchasable_item,
            :entry_fee,
            :with_stripe_product,
            value: entry_fee_amount,
            tournament: tournament
          )
        end
        let(:mock_checkout_session) do
          object_for_items([
            {
              item: entry_fee_item,
              quantity: 1,
            },
          ])
        end

        before do
          create(:purchase, bowler: bowler, purchasable_item: entry_fee_item, amount: entry_fee_amount)
        end

        it_behaves_like 'a Stripe event handler'
        it_behaves_like 'a completed checkout session'

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
          let(:item_1) do
            create(:purchasable_item,
              :scratch_competition,
              :with_stripe_product,
              tournament: tournament
            )
          end

          let(:item_2) do
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
          it_behaves_like 'a completed checkout session'

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

        context 'and some multi-use items' do
          let!(:item_1) do
            create(:purchasable_item,
              :banquet_entry,
              :with_stripe_product,
              tournament: tournament
            )
          end

          let!(:item_2) do
            create(:purchasable_item,
              :raffle_bundle,
              :with_stripe_product,
              value: 65,
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
                quantity: 2,
              },
              {
                item: item_2,
                quantity: 3,
              },
            ])
          end

          let(:expected_total) { entry_fee_item.value + item_1.value * 2 + item_2.value * 3 }

          it_behaves_like 'a Stripe event handler'
          it_behaves_like 'a completed checkout session'

          it 'creates a Purchase for each optional item' do
            expect { subject }.to change { bowler.purchases.count }.by(5)
          end

          it 'creates a ledger entry for each Purchase' do
            expect { subject }.to change { bowler.ledger_entries.purchase.count }.by(5)
          end

          it 'has the full payment amount on the LedgerEntry' do
            subject
            expect(bowler.ledger_entries.stripe.take.credit.to_i).to eq(expected_total)
          end
        end

        context 'and a late-registration fee' do
          let(:late_fee_item) do
            create(:purchasable_item,
              :late_fee,
              :with_stripe_product,
              value: 19,
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
                item: late_fee_item,
                quantity: 1,
              },
            ])
          end

          let(:expected_total) { entry_fee_item.value + late_fee_item.value }

          context 'because the bowler registered late' do
            # So the late-fee Purchase already exists when they make their payment

            before do
              create(:purchase, bowler: bowler, purchasable_item: late_fee_item, amount: late_fee_item.value)
            end

            it_behaves_like 'a Stripe event handler'
            it_behaves_like 'a completed checkout session'

            it 'creates no new Purchases' do
              expect { subject }.not_to change { bowler.purchases.count }
            end

            it 'has the full payment amount on the LedgerEntry' do
              subject
              expect(bowler.ledger_entries.stripe.take.credit).to eq(expected_total)
            end
          end

          context 'because the bowler waited too long to pay' do
            # So there is not a pre-existing late-fee Purchase

            it_behaves_like 'a Stripe event handler'
            it_behaves_like 'a completed checkout session'

            it 'creates a Purchase for the late fee item' do
              expect { subject }.to change { bowler.purchases.count }.by(1)
            end

            it 'creates a ledger entry for the Purchase' do
              expect { subject }.to change { bowler.ledger_entries.purchase.count }.by(1)
            end

            it 'has the full payment amount on the LedgerEntry' do
              subject
              expect(bowler.ledger_entries.stripe.take.credit).to eq(expected_total)
            end
          end
        end

        context 'and an early-registration fee' do
          let(:discount_item) do
            create(:purchasable_item,
              :early_discount,
              :with_stripe_coupon,
              value: 14,
              tournament: tournament
            )
          end

          let(:mock_checkout_session) do
            object_for_items([
              {
                item: entry_fee_item,
                quantity: 1,
                discounts: [ discount_item ],
              },
            ])
          end

          let(:expected_total) { entry_fee_item.value - discount_item.value }

          before do
            create(:purchase, bowler: bowler, purchasable_item: discount_item, amount: discount_item.value)
          end

          it_behaves_like 'a Stripe event handler'
          it_behaves_like 'a completed checkout session'

          it 'creates no new Purchases' do
            expect { subject }.not_to change { bowler.purchases.count }
          end

          it 'updates the paid_at attribute of the discount Purchase' do
            subject
            expect(bowler.purchases.early_discount.where(paid_at: nil)).to be_empty
          end

          it 'has the full payment amount on the LedgerEntry' do
            subject
            expect(bowler.ledger_entries.stripe.take.credit).to eq(expected_total)
          end
        end
      end

      context 'error conditions' do

      end
    end

  end
end
