require 'rails_helper'

RSpec.describe BowlersController, type: :controller do
  describe 'stripe_checkout' do
    subject do
      post :stripe_checkout,
        params: { identifier: bowler_identifier }.merge(submitted_data),
        as: :json
    end

    let(:uri) { "/bowlers/#{bowler_identifier}/stripe_checkout" }

    let(:submitted_data) do
      {
        purchase_identifiers: purchase_identifiers,
        purchasable_items: purchasable_items,
        expected_total: expected_total,
      }
    end
    let(:bowler) { create(:bowler, person: create(:person), tournament: tournament) }
    let(:bowler_identifier) { bowler.identifier }

    let(:chosen_items) { [] }
    let(:purchasable_items) do
      chosen_items.map { |item| { identifier: item.identifier, quantity: 1 } }
    end

    let(:purchase_identifiers) { bowler.purchases.unpaid.collect(&:identifier) }
    let(:expected_total) { 0 }
    let(:total_to_charge) { bowler.purchases.unpaid.sum(&:amount) + chosen_items.sum(&:value) }

    let(:stripe_response_url) { 'https://www.twitter.com' }
    let(:stripe_checkout_session_id) { 'stripe_checkout_session_abc123xyz789' }

    let(:expected_result) do
      {
        redirect_to: stripe_response_url,
        checkout_session_id: stripe_checkout_session_id,
      }
    end

    context 'a standard tournament' do
      let(:entry_fee_amount) { 117 }
      let(:early_discount_amount) { 13 }
      let(:late_fee_amount) { 24 }
      let(:tournament) { create :tournament, :active }
      let!(:entry_fee_item) do
        create(
          :purchasable_item,
          :entry_fee,
          :with_stripe_product,
          value: entry_fee_amount,
          tournament: tournament
        )
      end
      let!(:early_discount_item) do
        create(
          :purchasable_item,
          :early_discount,
          :with_stripe_coupon,
          value: early_discount_amount,
          tournament: tournament,
          configuration: { valid_until: 1.week.from_now }
        )
      end
      let!(:late_fee_item) do
        create(
          :purchasable_item,
          :late_fee,
          :with_stripe_product,
          value: late_fee_amount,
          tournament: tournament,
          configuration: { applies_at: 2.weeks.ago }
        )
      end

      before do
        allow(controller).to receive(:create_stripe_checkout_session).and_return(
          {
            url: stripe_response_url,
            id: stripe_checkout_session_id,
          }
        )
      end

      #     context 'when entry/early/late fees are already paid' do
      #       before do
      #         bowler.purchases << Purchase.new(purchasable_item: entry_fee_item, paid_at: 2.days.ago)
      #         bowler.purchases << Purchase.new(purchasable_item: early_discount_item, paid_at: 2.days.ago)
      #       end
      #
      #       context 'but we send their identifiers up anyway' do
      #         let(:purchase_identifiers) { bowler.purchases.collect(&:identifier) }
      #
      #         # expect error, since purchases are already paid-for
      #         it 'returns a Precondition Failed status code' do
      #           subject
      #           expect(response).to have_http_status(:precondition_failed)
      #         end
      #       end
      #
      #       context 'sending up no purchase identifiers' do
      #         # expect an error, because we ought to prevent purchasing nothing
      #         it 'returns a Precondition Failed status code' do
      #           subject
      #           expect(response).to have_http_status(:precondition_failed)
      #         end
      #
      #         context '...but with some chosen items' do
      #           let(:chosen_items) do
      #             [
      #               create(:purchasable_item, :scratch_competition, tournament: tournament),
      #               create(:purchasable_item, :optional_event, tournament: tournament),
      #             ]
      #           end
      #
      #           it 'returns an OK status code' do
      #             subject
      #             expect(response).to have_http_status(:ok)
      #           end
      #
      #           it 'returns the correct total' do
      #             subject
      #             result = JSON.parse(response.body)
      #             expect(result['total']).to eq(total_to_charge)
      #           end
      #         end
      #       end
      #     end
      #
      context 'regular registration' do
        let(:expected_total) { bowler.purchases.sum(&:amount) }

        # When a bowler registers, they get a Purchase for the entry fee
        before { bowler.purchases << Purchase.new(purchasable_item: entry_fee_item) }

        it 'returns an OK status code' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'includes a Stripe URL for redirection' do
          subject
          expect(json['redirect_to']).to eq(stripe_response_url)
        end

        it 'includes a Stripe checkout session id for the success page to use' do
          subject
          expect(json['checkout_session_id']).to eq(stripe_checkout_session_id)
        end

        context 'with early-registration discount' do
          before { bowler.purchases << Purchase.new(purchasable_item: early_discount_item) }

          it 'returns an OK status code' do
            subject
            expect(response).to have_http_status(:ok)
          end
        end

        context 'with late-registration fee' do
          before { bowler.purchases << Purchase.new(purchasable_item: late_fee_item) }

          it 'returns an OK status code' do
            subject
            expect(response).to have_http_status(:ok)
          end
        end

        context 'with some chosen items' do
          let(:chosen_items) do
            [
              create(:purchasable_item, :scratch_competition, :with_stripe_product, tournament: tournament),
              create(:purchasable_item, :optional_event, :with_stripe_product, tournament: tournament),
            ]
          end
          let(:expected_total) { total_to_charge }

          it 'returns an OK status code' do
            subject
            expect(response).to have_http_status(:ok)
          end

          context 'including a multi-use item' do
            let(:chosen_items) do
              [
                create(:purchasable_item, :scratch_competition, :with_stripe_product, tournament: tournament),
                create(:purchasable_item, :optional_event, :with_stripe_product, tournament: tournament),
                create(:purchasable_item, :banquet_entry, :with_stripe_product, tournament: tournament),
              ]
            end
            let(:expected_total) { total_to_charge }

            it 'returns an OK status code' do
              subject
              expect(response).to have_http_status(:ok)
            end
          end

          context 'including more than one of a multi-use item' do
            let(:banquet_item) { create(:purchasable_item, :banquet_entry, :with_stripe_product, tournament: tournament) }
            let(:chosen_items) do
              [
                create(:purchasable_item, :scratch_competition, :with_stripe_product, tournament: tournament),
                create(:purchasable_item, :optional_event, :with_stripe_product, tournament: tournament),
              ]
            end
            let(:purchasable_items) do
              chosen_items.map { |item| { identifier: item.identifier, quantity: 1 } }.push(
                { identifier: banquet_item.identifier, quantity: 3 }
              )
            end
            let(:total_to_charge) { bowler.purchases.unpaid.sum(&:amount) + chosen_items.sum(&:value) + banquet_item.value * 3 }
            let(:expected_total) { total_to_charge }

            it 'returns an OK status code' do
              subject
              expect(response).to have_http_status(:ok)
            end
          end
        end
      end

      context 'error conditions' do
        context 'an unknown bowler identifier' do
          let(:bowler_identifier) { 'gobbledegook' }

          it 'renders a 404 Not Found' do
            subject
            expect(response).to have_http_status(:not_found)
          end
        end

        context 'with an unknown item identifier' do
          let(:purchasable_items) do
            [
              {
                identifier: 'gobbledegook',
                quantity: 1,
              }
            ]
          end

          it 'renders a 404 Not Found' do
            subject
            expect(response).to have_http_status(:not_found)
          end
        end

        context 'with an unknown purchase identifier' do
          let(:purchase_identifiers) { ['gobbledegook'] }

          # This is the same result as passing up the identifier of a paid-for purchase
          it 'renders a 412 Precondition Failed' do
            subject
            expect(response).to have_http_status(:precondition_failed)
          end
        end

        context 'attempting to buy more than one of a single-use item' do
          let(:item) { create(:purchasable_item, :optional_event, :with_stripe_product, tournament: tournament) }
          let(:purchasable_items) { [{ identifier: item.identifier, quantity: 2 }] }
          let(:total_to_charge) { item.value * 2 }
          let(:expected_total) { total_to_charge }

          it 'returns a 422 status code' do
            subject
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context 'buying a single-use item when one has already been purchased' do
          let(:item) { create(:purchasable_item, :optional_event, :with_stripe_product, tournament: tournament) }
          let(:chosen_items) { [item] }

          before do
            bowler.purchases << Purchase.new(purchasable_item: item, paid_at: 2.days.ago)
          end

          it 'returns a 412 status code' do
            subject
            expect(response).to have_http_status(:precondition_failed)
          end
        end
      end
    end
  end
end
