require 'rails_helper'

describe BowlersController, type: :request do
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end

  describe '#create' do
    subject { post uri, params: joining_bowler_params, as: :json }

    let(:uri) { "/teams/#{team.identifier}/bowlers" }
    let(:tournament) { create :tournament, :active, :with_entry_fee }

    before do
      comment = create(:extended_form_field, :comment)
      pronouns = create(:extended_form_field, :pronouns)
      standings = create(:extended_form_field, :standings_link)

      create(:additional_question, extended_form_field: comment, tournament: tournament)
      create(:additional_question, extended_form_field: pronouns, tournament: tournament)
      create(:additional_question, extended_form_field: standings, tournament: tournament)
    end

    context 'with valid bowler input' do
      let(:joining_bowler_params) do
        {
          bowler: joining_bowler_test_data.merge({ position: 4 })
        }
      end

      context 'with a partial team' do
        let(:team) { create(:team, :standard_three_bowlers, tournament: tournament) }

        it 'succeeds' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'includes the new team in the response' do
          subject
          expect(json).to have_key('identifier')
        end
      end

      context 'with a full team' do
        let(:team) { create(:team, :standard_full_team, tournament: tournament) }

        it 'fails' do
          subject
          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    context 'with invalid data' do
      let(:team) { create(:team, :standard_three_bowlers, tournament: tournament) }
      let(:joining_bowler_params) do
        {
          bowler: invalid_joining_bowler_test_data.merge({position: 4})
        }
      end

      it 'fails' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe '#show' do
    subject { get uri, as: :json }

    let(:uri) { "/bowlers/#{bowler.identifier}" }
    let(:tournament) { create :tournament, :active, :with_entry_fee }
    let(:team) { create :team, tournament: tournament }
    let(:bowler) { create :bowler, team: team, tournament: tournament }

    it 'succeeds' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'includes bowler details' do
      subject
      bowlerDeets = json['bowler']
      expect(bowlerDeets['identifier']).to eq(bowler.identifier)
      expect(bowlerDeets['first_name']).to eq(bowler.first_name)
      expect(bowlerDeets['last_name']).to eq(bowler.last_name)
    end

    it 'includes purchase details' do
      subject
      bowlerDeets = json['bowler']
      expect(bowlerDeets).to have_key('amount_due')
      expect(bowlerDeets).to have_key('amount_billed')
      expect(bowlerDeets).to have_key('unpaid_purchases')
      expect(bowlerDeets).to have_key('paid_purchases')
    end

    context 'a bowler with a nickname' do
      let(:person) { create :person, nickname: 'Gorgeous' }
      let(:bowler) { create :bowler, team: team, tournament: tournament, person: person }

      it 'includes the preferred name' do
        subject
        expect(json['bowler']['preferred_name']).to eq(bowler.nickname)
      end
    end

    context 'a non-existent bowler' do
      let(:uri) { '/bowlers/this-person-does-not-exist' }

      it 'returns a 404 Not Found' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'concerning the entry fee' do
      let(:entry_fee_item) { tournament.purchasable_items.ledger.first }

      context 'when the bowler has not paid' do
        before do
          # give the bowler the entry fee as an unpaid purchase
          create :purchase, amount: entry_fee_item.value, purchasable_item: entry_fee_item, bowler: bowler
        end

        it 'includes the entry fee in unpaid purchases' do
          subject
          expect(json['bowler']['unpaid_purchases'].count).to eq(1)
          expect(json['bowler']['unpaid_purchases'].first['amount']).to eq(entry_fee_item.value)
        end
      end

      context 'when the bowler has paid' do
        before do
          # give the bowler the entry fee as an unpaid purchase
          create :purchase, :paid, amount: entry_fee_item.value, purchasable_item: entry_fee_item, bowler: bowler
        end

        it 'does not include the entry fee in unpaid purchases' do
          subject
          expect(json['bowler']['unpaid_purchases']).to be_empty
        end

        it 'includes the entry fee in paid purchases' do
          subject
          expect(json['bowler']['paid_purchases'].count).to eq(1)
          expect(json['bowler']['paid_purchases'].first['amount']).to eq(entry_fee_item.value)
        end
      end
    end

    context 'available purchasable items' do
      let(:tournament) { create :tournament,
                                :active,
                                :with_entry_fee,
                                :with_scratch_competition_divisions,
                                :with_an_optional_event,
                                :with_a_banquet }

      it 'has available items' do
        subject
        expect(json['available_items']).not_to be_empty
      end

      it 'renders them as a hash, with identifiers as keys' do
        subject
        expect(json['available_items']).to be_instance_of(Hash)
        item_keys = json['available_items'].keys
        key = item_keys.first
        expect(json['available_items'][key]['identifier']).to eq(key)
      end

      it 'excludes the entry fee from available items' do
        subject
        item_keys = json['available_items'].keys
        entry_fee_identifier = tournament.purchasable_items.entry_fee.first.identifier
        expect(item_keys).not_to include(entry_fee_identifier)
      end
    end
  end

  describe '#purchase_details' do
    subject { post uri, params: submitted_data, as: :json }

    let(:uri) { "/bowlers/#{bowler_identifier}/purchase_details" }

    let(:submitted_data) do
      {
        purchase_identifiers: purchase_identifiers,
        purchasable_items: purchasable_items,
        expected_total: expected_total,
      }
    end
    let(:tournament) { create :tournament, :active, :accepting_payments }
    let(:bowler) { create(:bowler, person: create(:person), tournament: tournament) }
    let!(:entry_fee_item) { create(:purchasable_item, :entry_fee, value: entry_fee_amount, tournament: tournament) }
    let!(:early_discount_item) { create(:purchasable_item, :early_discount, value: early_discount_amount, tournament: tournament, configuration: { valid_until: 1.week.from_now }) }
    let!(:late_fee_item) { create(:purchasable_item, :late_fee, value: late_fee_amount, tournament: tournament, configuration: { applies_at: 2.weeks.ago }) }

    let(:chosen_items) { [] }
    let(:purchasable_items) do
      chosen_items.map { |item| { identifier: item.identifier, quantity: 1} }
    end

    let(:bowler_identifier) { bowler.identifier }
    let(:purchase_identifiers) { bowler.purchases.unpaid.collect(&:identifier) }
    let(:expected_total) { 0 }
    let(:client_id) { tournament.paypal_client_id }
    let(:total_to_charge) { bowler.purchases.unpaid.sum(&:amount) + chosen_items.sum(&:value) }
    let(:entry_fee_amount) { 117 }
    let(:early_discount_amount) { -13 }
    let(:late_fee_amount) { 24 }

    let(:expected_result) do
      {
        client_id: client_id,
        total_to_charge: total_to_charge,
      }
    end

    context 'when entry/early/late fees are already paid' do
      before do
        bowler.purchases << Purchase.new(purchasable_item: entry_fee_item, paid_at: 2.days.ago)
        bowler.purchases << Purchase.new(purchasable_item: early_discount_item, paid_at: 2.days.ago)
      end

      context 'but we send their identifiers up anyway' do
        let(:purchase_identifiers) { bowler.purchases.collect(&:identifier) }

        # expect error, since purchases are already paid-for
        it 'returns a Precondition Failed status code' do
          subject
          expect(response).to have_http_status(:precondition_failed)
        end
      end

      context 'sending up no purchase identifiers' do
        # expect an error, because we ought to prevent purchasing nothing
        it 'returns a Precondition Failed status code' do
          subject
          expect(response).to have_http_status(:precondition_failed)
        end

        context '...but with some chosen items' do
          let(:chosen_items) do
            [
              create(:purchasable_item, :scratch_competition, tournament: tournament),
              create(:purchasable_item, :optional_event, tournament: tournament),
            ]
          end

          it 'returns an OK status code' do
            subject
            expect(response).to have_http_status(:ok)
          end

          it 'returns the correct total' do
            subject
            result = JSON.parse(response.body)
            expect(result['total']).to eq(total_to_charge)
          end
        end
      end
    end

    context 'regular registration' do
      let(:expected_total) { bowler.purchases.sum(&:amount) }

      # When a bowler registers, they get a Purchase for the entry fee
      before { bowler.purchases << Purchase.new(purchasable_item: entry_fee_item) }

      it 'returns an OK status code' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'returns the correct total' do
        subject
        result = JSON.parse(response.body)
        expect(result['total']).to eq(total_to_charge)
      end

      it 'includes the expected paypal client id' do
        subject
        result = JSON.parse(response.body)
        expect(result['paypal_client_id']).to eq(client_id)
      end

      context 'with early-registration discount' do
        before { bowler.purchases << Purchase.new(purchasable_item: early_discount_item) }

        it 'returns an OK status code' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'returns the correct total' do
          subject
          result = JSON.parse(response.body)
          expect(result['total']).to eq(total_to_charge)
        end
      end

      context 'with late-registration fee' do
        before { bowler.purchases << Purchase.new(purchasable_item: late_fee_item) }

        it 'returns an OK status code' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'returns the correct total' do
          subject
          result = JSON.parse(response.body)
          expect(result['total']).to eq(total_to_charge)
        end
      end

      context 'with some chosen items' do
        let(:chosen_items) do
          [
            create(:purchasable_item, :scratch_competition, tournament: tournament),
            create(:purchasable_item, :optional_event, tournament: tournament),
          ]
        end
        let(:expected_total) { total_to_charge }

        it 'returns an OK status code' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'returns the correct total' do
          subject
          result = JSON.parse(response.body)
          expect(result['total']).to eq(total_to_charge)
        end

        context 'including a multi-use item' do
          let(:chosen_items) do
            [
              create(:purchasable_item, :scratch_competition, tournament: tournament),
              create(:purchasable_item, :optional_event, tournament: tournament),
              create(:purchasable_item, :banquet_entry, tournament: tournament),
            ]
          end
          let(:expected_total) { total_to_charge }

          it 'returns an OK status code' do
            subject
            expect(response).to have_http_status(:ok)
          end

          it 'returns the correct total' do
            subject
            result = JSON.parse(response.body)
            expect(result['total']).to eq(total_to_charge)
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
            chosen_items.map { |item| { identifier: item.identifier, quantity: 1} }.push(
              { identifier: banquet_item.identifier, quantity: 3 }
            )
          end
          let(:total_to_charge) { bowler.purchases.unpaid.sum(&:amount) + chosen_items.sum(&:value) + banquet_item.value * 3 }
          let(:expected_total) { total_to_charge }

          it 'returns an OK status code' do
            subject
            expect(response).to have_http_status(:ok)
          end

          it 'returns the correct total' do
            subject
            result = JSON.parse(response.body)
            expect(result['total']).to eq(total_to_charge)
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
        let(:item) { create(:purchasable_item, :optional_event, tournament: tournament) }
        let(:purchasable_items) { [ { identifier: item.identifier, quantity: 2 } ] }
        let(:total_to_charge) { item.value * 2 }
        let(:expected_total) { total_to_charge }

        it 'returns a 422 status code' do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'buying a single-use item when one has already been purchased' do
        let(:item) { create(:purchasable_item, :optional_event, tournament: tournament) }
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

