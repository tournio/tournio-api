require "rails_helper"

RSpec.describe Stripe::CheckoutSessionCompleted, type: :job do
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
    let(:tournament) { create :tournament, :active }
    let(:bowler) { create :bowler, tournament: tournament }
    let(:mock_checkout_session) { object_for_items([]) }

    subject { event_handler.handle_event }

    before do
      allow(event_handler).to receive(:event).and_return(mock_event)
      allow(event_handler).to receive(:retrieve_stripe_object).and_return(mock_checkout_session)
    end

    context 'a regular checkout session' do
      before do
        create :stripe_checkout_session,
          bowler: bowler,
          identifier: mock_checkout_session[:id]
      end

      it_behaves_like 'a Stripe event handler'
      it_behaves_like 'a completed checkout session'

      it 'marks the checkout session as completed' do
        subject
        sesh = bowler.stripe_checkout_sessions.last
        expect(sesh.completed?).to be_truthy
      end

      it 'correctly populates the identifier on the Stripe LedgerEntry' do
        subject
        pi_identifier = mock_checkout_session[:payment_intent]
        expect(LedgerEntry.stripe.last.identifier).to eq(pi_identifier)
      end

      it 'correctly gives the Stripe LedgerEntry a zero debit' do
        subject
        expect(LedgerEntry.stripe.last.debit).to eq(0.0)
      end

      it 'correctly gives the Stripe LedgerEntry credit equal to the total amount' do
        subject
        expect(LedgerEntry.stripe.last.credit).to eq(mock_checkout_session[:amount_total] / 100)
      end

      it 'does not send a receipt email' do
        expect(TournamentRegistration).not_to receive(:send_receipt_email)
        subject
      end

      context 'with the config item for sending receipts via Stripe disabled' do
        before do
          tournament.config_items.find_by(key: 'stripe_receipts').update(value: 'false')
        end

        it 'sends a receipt email' do
          expect(TournamentRegistration).to receive(:send_receipt_email).once
          subject
        end
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

        it 'creates a Purchase for the entry fee' do
          expect { subject }.to change { bowler.purchases.entry_fee.count }.by(1)
        end

        it 'associates the ExternalPayment to the entry-fee Purchase' do
          subject
          expect(bowler.purchases.entry_fee.first.external_payment_id).to eq(ExternalPayment.last.id)
        end

        it 'marks the entry-fee purchase as paid' do
          subject
          expect(bowler.purchases.entry_fee.first.paid_at).not_to be_nil
        end

        it 'winds up with a zero balance' do
          subject
          expect(TournamentRegistration.amount_due(bowler)).to be_zero
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

          it 'winds up with a zero balance' do
            subject
            expect(TournamentRegistration.amount_due(bowler)).to be_zero
          end

          it 'creates a Purchase for each optional item' do
            expect { subject }.to change { bowler.purchases.count }.by(3)
          end

          it 'creates a ledger entry for each Purchase' do
            expect { subject }.to change { bowler.ledger_entries.purchase.count }.by(3)
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

          it 'winds up with a zero balance' do
            subject
            expect(TournamentRegistration.amount_due(bowler)).to be_zero
          end

          it 'creates a Purchase for each optional item' do
            expect { subject }.to change { bowler.purchases.count }.by(6)
          end

          it 'creates a ledger entry for each Purchase' do
            expect { subject }.to change { bowler.ledger_entries.purchase.count }.by(6)
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

          it 'winds up with a zero balance' do
            subject
            expect(TournamentRegistration.amount_due(bowler)).to be_zero
          end

          context 'because the bowler registered late' do
            it_behaves_like 'a Stripe event handler'
            it_behaves_like 'a completed checkout session'

            it 'creates a Purchase for the late fee item and the entry fee' do
              expect { subject }.to change { bowler.purchases.count }.by(2)
            end

            it 'creates a ledger entry for the Purchase' do
              expect { subject }.to change { bowler.ledger_entries.purchase.count }.by(2)
            end
          end
        end

        context 'and an early-registration discount' do
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
                discounts: [discount_item],
              },
            ])
          end

          it 'winds up with a zero balance' do
            subject
            expect(TournamentRegistration.amount_due(bowler)).to be_zero
          end

          it 'creates two new Purchase objects' do
            expect { subject }.to change { bowler.purchases.count }.by(2)
          end

          it 'updates the paid_at attribute of the discount Purchase' do
            subject
            expect(bowler.purchases.early_discount.where(paid_at: nil).count).to be_zero
          end
        end
      end

      context 'with events' do
        # order of operations is a pain in the rear!
        let(:event_item_1) { create :purchasable_item, :bowling_event, :with_stripe_product, tournament: tournament }
        let(:event_item_2) { create :purchasable_item, :bowling_event, :with_stripe_product, tournament: tournament }

        let(:mock_checkout_session) do
          # Both items have the same Discount, because that's how Stripe gives it to us.
          object_for_items([
            {
              item: event_item_1,
              quantity: 1,
            },
            {
              # event item 2
              item: event_item_2,
              quantity: 1,
            },
          ])
        end

        before do
          create :stripe_checkout_session,
            bowler: bowler,
            identifier: mock_checkout_session[:id]
        end

        it 'creates two event purchases' do
          expect{ subject }.to change(bowler.purchases.event, :count).by(2)
        end

        it 'associates the ExternalPayment to all new Purchases' do
          subject
          expect(bowler.purchases.pluck(:external_payment_id).uniq.count).to eq(1)
        end

        it 'tallies up owed correctly' do
          subject
          owed = TournamentRegistration.amount_due bowler
          expect(owed).to be_zero
        end

        context 'with an applicable bundle discount' do
          let(:discount_item) do
            create :purchasable_item,
              :with_stripe_coupon,
              tournament: tournament,
              category: :ledger,
              determination: :bundle_discount,
              name: 'Combo Pack',
              value: 20
          end

          let(:mock_checkout_session) do
            # Both items have the same Discount, because that's how Stripe gives it to us.
            object_for_items([
              {
                item: event_item_1,
                quantity: 1,
                discounts: [discount_item],
              },
              {
                # event item 2
                item: event_item_2,
                quantity: 1,
                discounts: [discount_item],
              },
            ])
          end

          it 'creates two event purchases' do
            expect{ subject }.to change(bowler.purchases.event, :count).by(2)
          end

          it 'associates the ExternalPayment to all new Purchases' do
            subject
            expect(bowler.purchases.pluck(:external_payment_id).uniq.count).to eq(1)
          end

          it 'tallies up owed correctly' do
            subject
            owed = TournamentRegistration.amount_due bowler
            expect(owed).to be_zero
          end

          it 'creates one bundle discount purchase' do
            expect{ subject }.to change(bowler.purchases.ledger, :count).by(1)
          end

          it 'identifies the discount item' do
            subject
            items = bowler.ledger_entries.where(identifier: discount_item.name)
            expect(items.count).to be_positive
          end
        end
      end
    end

    context 'a checkout session we did not create' do
      it 'raises no error' do
        expect { subject }.not_to raise_error
      end

      it 'does not create an ExternalPayment' do
        expect { subject }.not_to change(ExternalPayment, :count)
      end

      it 'does not create any Purchases' do
        expect { subject }.not_to change(Purchase, :count)
      end
    end

    context 'error conditions' do

    end

    describe 'using a real-world example from Stripe' do

      let(:mock_checkout_session) { real_checkout_session }

      let(:entry_fee_amount) { 120 }
      let(:entry_fee_item) do
        create(:purchasable_item,
          :entry_fee,
          :with_stripe_product,
          value: entry_fee_amount,
          tournament: tournament
        )
      end
      let(:discount_item) do
        create(:purchasable_item,
          :early_discount,
          :with_stripe_coupon,
          value: 10,
          tournament: tournament
        )
      end

      before do
        entry_fee_item.stripe_product.update(price_id: 'price_1O6QifIorUnGjsWjKZ03KPNd', product_id: 'prod_OuFDqBYJV0yny6')
        discount_item.stripe_coupon.update(coupon_id: 'PmiNeEIO')
        create :stripe_checkout_session,
          bowler: bowler,
          identifier: mock_checkout_session[:id]
      end

      it 'associates the ExternalPayment to the entry-fee Purchase' do
        subject
        expect(bowler.purchases.entry_fee.first.external_payment_id).to eq(ExternalPayment.last.id)
      end

      it 'marks the entry-fee purchase as paid' do
        subject
        expect(bowler.purchases.entry_fee.first.paid_at).not_to be_nil
      end

      it 'creates a new Purchase object for the entry fee' do
        expect { subject }.to change { bowler.purchases.entry_fee.count }
      end

      it 'creates a new Purchase object for the discount' do
        expect { subject }.to change { bowler.purchases.early_discount.count }
      end

      it 'updates the paid_at attribute of the discount Purchase' do
        subject
        expect(bowler.purchases.early_discount.where(paid_at: nil).count).to be_zero
      end

      it 'winds up with a zero balance' do
        subject
        expect(TournamentRegistration.amount_due(bowler)).to be_zero
      end

    end
  end
end
