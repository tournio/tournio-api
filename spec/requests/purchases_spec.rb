require 'rails_helper'

describe PurchasesController, type: :request do
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end

  describe '#create' do
    subject { post url, params: submitted_data, as: :json }

    let(:url) { "/bowlers/#{bowler_identifier}/purchases" }

    let(:submitted_data) do
      {
        purchase_identifiers: purchase_identifiers,
        purchasable_items: purchasable_items,
        paypal_details: paypal_details,
      }
    end
    let(:tournament) { create :tournament, :active, :accepting_payments }
    let(:bowler) { create(:bowler, person: create(:person), tournament: tournament) }
    let!(:entry_fee_item) { create(:purchasable_item, :entry_fee, value: entry_fee_amount, tournament: tournament) }
    let!(:early_discount_item) { create(:purchasable_item, :early_discount, value: early_discount_amount, tournament: tournament, configuration: { valid_until: 1.week.from_now }) }
    let!(:late_fee_item) { create(:purchasable_item, :late_fee, value: late_fee_amount, tournament: tournament, configuration: { applies_at: 2.weeks.ago }) }
    let(:paypal_details) do
      {
        id: 'abc123paypal789xyz',
        payer: {},
        purchase_units: {},
      }
    end

    let(:chosen_items) { [] }
    let(:purchasable_items) do
      chosen_items.map { |item| { identifier: item.identifier, quantity: 1 } }
    end

    let(:bowler_identifier) { bowler.identifier }
    let(:purchase_identifiers) { bowler.purchases.unpaid.collect(&:identifier) }
    let(:expected_total) { 0 }
    let(:entry_fee_amount) { 117 }
    let(:early_discount_amount) { -13 }
    let(:late_fee_amount) { 24 }

    context 'regular registration' do
      let(:expected_total) { bowler.purchases.sum(&:amount) }
      let(:purchase) { Purchase.new(purchasable_item: entry_fee_item) }

      # When a bowler registers, they get a Purchase for the entry fee
      before { bowler.purchases << purchase }

      it 'returns a Created status code' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'includes an array representation of the purchases in the response' do
        subject
        expect(json).to be_instance_of(Array)
        expect(json[0]['identifier']).to eq(purchase.identifier)
      end

      it 'updates the paid_at attribute on the purchase' do
        subject
        expect(purchase.reload.paid_at).not_to be_nil
      end

      it 'creates a paypal order' do
        expect { subject }.to change { PaypalOrder.count }.by(1)
      end

      it 'links the purchase to the paypal order' do
        subject
        ppo = PaypalOrder.last
        expect(purchase.reload.paypal_order_id).to eq(ppo.id)
      end

      it 'creates a ledger entry' do
        expect { subject }.to change { LedgerEntry.count }.by(1)
      end

      it 'creates a ledger entry in the amount of the expected total' do
        subject
        le = bowler.ledger_entries.last
        expect(le.credit).to eq(expected_total)
      end

      context 'with early-registration discount' do
        let(:purchase2) { Purchase.new(purchasable_item: early_discount_item) }
        before { bowler.purchases << purchase2 }

        it 'returns a Created status code' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'updates the paid_at attribute on the additional purchase' do
          subject
          expect(purchase2.reload.paid_at).not_to be_nil
        end

        it 'links the additional purchase to the paypal order' do
          subject
          ppo = PaypalOrder.last
          expect(purchase2.reload.paypal_order_id).to eq(ppo.id)
        end

        it 'creates a ledger entry' do
          expect { subject }.to change { LedgerEntry.count }.by(1)
        end

        it 'creates a ledger entry in the amount of the expected total' do
          subject
          le = bowler.ledger_entries.last
          expect(le.credit).to eq(expected_total)
        end
      end

      context 'with late-registration fee' do
        let(:purchase2) { Purchase.new(purchasable_item: late_fee_item) }
        before { bowler.purchases << purchase2 }

        it 'returns a Created status code' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'updates the paid_at attribute on the additional purchase' do
          subject
          expect(purchase2.reload.paid_at).not_to be_nil
        end

        it 'links the additional purchase to the paypal order' do
          subject
          ppo = PaypalOrder.last
          expect(purchase2.reload.paypal_order_id).to eq(ppo.id)
        end

        it 'creates a ledger entry' do
          expect { subject }.to change { LedgerEntry.count }.by(1)
        end

        it 'creates a ledger entry in the amount of the expected total' do
          subject
          le = bowler.ledger_entries.last
          expect(le.credit).to eq(expected_total)
        end
      end

      context 'with some chosen items' do
        let(:chosen_items) do
          [
            create(:purchasable_item, :scratch_competition, tournament: tournament),
            create(:purchasable_item, :optional_event, tournament: tournament),
          ]
        end

        it 'returns a Created status code' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'creates Purchases for each purchasable item specified' do
          expect { subject }.to change { Purchase.count }.by(2)
        end

        it 'creates a ledger entry for each purchase and the payment' do
          expect { subject }.to change { LedgerEntry.count }.by(3)
        end

        it 'creates a ledger entry in the amount of the expected total' do
          subject
          le = bowler.ledger_entries.last
          expect(le.credit).to eq(expected_total)
        end

        context 'including a multi-use item' do
          let(:chosen_items) do
            [
              create(:purchasable_item, :scratch_competition, tournament: tournament),
              create(:purchasable_item, :optional_event, tournament: tournament),
              create(:purchasable_item, :banquet_entry, tournament: tournament),
            ]
          end

          it 'returns a Created status code' do
            subject
            expect(response).to have_http_status(:created)
          end

          it 'creates Purchases for each purchasable item specified' do
            expect { subject }.to change { Purchase.count }.by(3)
          end

          it 'links the new purchases to the paypal order' do
            subject
            ppo = PaypalOrder.last
            purchases = Purchase.last(3)
            purchases.each { |p| expect(p.paypal_order_id).to eq(ppo.id) }
          end

          it 'creates a ledger entry for each purchase and the payment' do
            expect { subject }.to change { LedgerEntry.count }.by(4)
          end

          it 'creates a ledger entry in the amount of the expected total' do
            subject
            le = bowler.ledger_entries.last
            expect(le.credit).to eq(expected_total)
          end
        end

        context 'including more than one of a multi-use item' do
          let(:banquet_item) { create(:purchasable_item, :banquet_entry, tournament: tournament) }
          let(:chosen_items) do
            [
              create(:purchasable_item, :scratch_competition, tournament: tournament),
              create(:purchasable_item, :optional_event, tournament: tournament),
            ]
          end
          let(:purchasable_items) do
            chosen_items.map { |item| { identifier: item.identifier, quantity: 1 } }.push(
              { identifier: banquet_item.identifier, quantity: 3 }
            )
          end

          it 'returns a Created status code' do
            subject
            expect(response).to have_http_status(:created)
          end

          it 'creates Purchases for each purchasable item specified' do
            expect { subject }.to change { Purchase.count }.by(5)
          end

          it 'links the new purchases to the paypal order' do
            subject
            ppo = PaypalOrder.last
            purchases = Purchase.last(5)
            purchases.each { |p| expect(p.paypal_order_id).to eq(ppo.id) }
          end

          it 'creates a ledger entry for each purchase and the payment' do
            expect { subject }.to change { LedgerEntry.count }.by(6)
          end

          it 'creates a ledger entry in the amount of the expected total' do
            subject
            le = bowler.ledger_entries.last
            expect(le.credit).to eq(expected_total)
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

        it 'creates no ledger entry' do
          expect { subject }.not_to change { LedgerEntry.count }
        end
      end

      context 'creating no purchases' do
        let(:purchase_identifiers) { [] }

        it 'renders a 204 No Content' do
          subject
          expect(response).to have_http_status(:no_content)
        end

        it 'creates no ledger entry' do
          expect { subject }.not_to change { LedgerEntry.count }
        end

        it 'creates no new purchase' do
          expect { subject }.not_to change { Purchase.count }
        end
      end
    end
  end
end
