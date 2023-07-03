require "rails_helper"

RSpec.describe Stripe::CheckoutSessionExpired, type: :job do
  describe '#handle_event' do
    # When this method runs, the job's "event" attribute has already been set.
    #
    # the event's object is a checkout session

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

      context 'a regular checkout session' do
        before do
          create :stripe_checkout_session,
            bowler: bowler,
            identifier: mock_checkout_session[:id]
        end

        it 'marks the checkout session as expired' do
          subject
          sesh = bowler.stripe_checkout_sessions.last
          expect(sesh.expired?).to be_truthy
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

          it 'does not mark the entry-fee purchase as paid' do
            subject
            expect(bowler.purchases.entry_fee.first.paid_at).to be_nil
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

            it 'creates no Purchases for the optional items' do
              expect { subject }.not_to change { bowler.purchases.count }
            end

            it 'creates no Purchase ledger entries' do
              expect { subject }.not_to change { bowler.ledger_entries.purchase.count }
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

            it 'creates no Purchases for the optional items' do
              expect { subject }.not_to change { bowler.purchases.count }
            end

            it 'creates no Purchase ledger entries' do
              expect { subject }.not_to change { bowler.ledger_entries.purchase.count }
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

              it 'creates no new Purchases' do
                expect { subject }.not_to change { bowler.purchases.count }
              end
            end

            context 'because the bowler waited too long to pay' do
              # So there is not a pre-existing late-fee Purchase

              it_behaves_like 'a Stripe event handler'

              it 'creates no new Purchase' do
                expect { subject }.not_to change { bowler.purchases.count }
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
                  discounts: [ discount_item ],
                },
              ])
            end

            let(:expected_total) { entry_fee_item.value - discount_item.value }

            before do
              create(:purchase, bowler: bowler, purchasable_item: discount_item, amount: discount_item.value)
            end

            it_behaves_like 'a Stripe event handler'

            it 'creates no new Purchases' do
              expect { subject }.not_to change { bowler.purchases.count }
            end

            it 'does not update the paid_at attribute of the discount Purchase' do
              subject
              expect(bowler.purchases.early_discount.where(paid_at: nil)).not_to be_empty
            end
          end
        end
      end

      context 'a checkout session we did not create' do
        it 'raises no error' do
          expect { subject }.not_to raise_error
        end
      end

      context 'error conditions' do

      end
    end
  end
end
