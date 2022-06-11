require 'rails_helper'

describe BowlersController, type: :request do
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end

  describe '#index' do
    subject { get uri, as: :json }

    let(:tournament) { create :tournament, :active, :one_shift, :with_event_selection }
    let(:tournament_identifier) { tournament.identifier }
    let(:uri) { "/tournaments/#{tournament_identifier}/bowlers" }

    before do
      10.times do |i|
        create :bowler, tournament: tournament, position: nil
      end
    end

    it 'returns 200 OK' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'is an array of bowlers' do
      subject
      expect(json).to be_an_instance_of(Array)
    end

    it 'includes all bowlers in the response' do
      subject
      expect(json.count).to eq(10)
    end

    context 'an unknown tournament identifier' do
      let(:tournament_identifier) { 'i-dont-know-her' }

      it 'returns a Not Found' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe '#create' do
    subject { post uri, params: bowler_params, as: :json }

    let(:tournament) { create :tournament, :active, :with_entry_fee }

    before do
      comment = create(:extended_form_field, :comment)
      pronouns = create(:extended_form_field, :pronouns)
      standings = create(:extended_form_field, :standings_link)

      create(:additional_question, extended_form_field: comment, tournament: tournament)
      create(:additional_question, extended_form_field: pronouns, tournament: tournament)
      create(:additional_question, extended_form_field: standings, tournament: tournament)
    end

    context 'joining a team on a standard tournament' do
      let(:uri) { "/teams/#{team.identifier}/bowlers" }

      context 'with valid bowler input' do
        let(:bowler_params) do
          {
            bowlers: [create_bowler_test_data.merge({ position: 4 })]
          }
        end

        context 'with a partial team' do
          let(:team) { create(:team, :standard_three_bowlers, tournament: tournament) }

          it 'succeeds' do
            subject
            expect(response).to have_http_status(:created)
          end

          it 'includes the bowler identifier in the response' do
            subject
            bowler = Bowler.last
            expect(json[0]['identifier']).to eq(bowler.identifier)
          end

          context 'a team on a shift' do
            let(:shift) { create :shift, :high_demand, tournament: tournament }
            let!(:shift_team) { create :shift_team, shift: shift, team: team }

            it 'bumps the requested count by one' do
              expect { subject }.to change { shift.reload.requested }.by(1)
            end

            it 'does not bump the confirmed count' do
              expect { subject }.not_to change { shift.reload.confirmed }
            end

            context 'the team is confirmed on the shift' do
              let!(:shift_team) { create :shift_team, shift: shift, team: team, aasm_state: :confirmed, confirmed_at: 3.days.ago }

              it 'bumps the confirmed count by one' do
                expect { subject }.to change { shift.reload.confirmed }.by(1)
              end

              it 'does not bump the confirmed count' do
                expect { subject }.not_to change { shift.reload.requested }
              end
            end
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
        let(:bowler_params) do
          {
            bowlers: [invalid_create_bowler_test_data.merge({position: 4})]
          }
        end

        it 'fails' do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'registering as an individual' do
      let(:uri) { "/tournaments/#{tournament.identifier}/bowlers" }
      let(:bowler_params) do
        {
          bowlers: [create_bowler_test_data],
        }
      end

      it 'does not create a new team for the bowler' do
        expect{ subject }.not_to change(Team, :count)
      end

      it 'succeeds' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'creates a new bowler' do
        expect{ subject }.to change(Bowler, :count).by(1)
      end

      it 'includes the new bowler in the response' do
        subject
        bowler = Bowler.last
        expect(json[0]['identifier']).to eq(bowler.identifier)
      end

      it 'creates an entry-fee purchase for the bowler' do
        subject
        bowler = Bowler.last
        expect(bowler.purchases.entry_fee).not_to be_empty
      end

      context 'a tournament with event selection' do
        let(:tournament) { create :tournament, :active, :with_event_selection, :with_a_bowling_event }

        it 'succeeds' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'does not create any entry-fee purchases' do
          expect { subject }.not_to change(Purchase, :count)
        end

        context 'partnering up with an already-registered bowler' do
          let!(:target) { create :bowler, tournament: tournament, position: nil }
          let(:bowler_params) do
            {
              bowlers: [create_bowler_test_data.merge({
                doubles_partner_identifier: target.identifier,
              })],
            }
          end

          it 'succeeds' do
            subject
            expect(response).to have_http_status(:created)
          end

          it 'creates a bowler' do
            expect { subject }.to change(Bowler, :count).by(1)
          end

          it 'partners up the bowler with the target' do
            subject
            bowler = Bowler.last
            expect(bowler.doubles_partner_id).to eq(target.id)
          end

          it 'reciprocates the partnership' do
            subject
            bowler = Bowler.last
            expect(target.reload.doubles_partner_id).to eq(bowler.id)
          end
        end
      end
    end

    context 'registering as a doubles pair' do
      let(:tournament) { create :tournament, :active, :with_event_selection, :with_a_bowling_event }
      let(:uri) { "/tournaments/#{tournament.identifier}/bowlers" }
      let(:bowler_params) do
        {
          bowlers: create_doubles_test_data,
        }
      end

      it 'succeeds' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'does not create any entry-fee purchases' do
        expect { subject }.not_to change(Purchase, :count)
      end

      it 'creates two bowlers' do
        expect { subject }.to change(Bowler, :count).by(2)
      end

      it 'partners up the two bowlers' do
        subject
        bowlers = Bowler.last(2)
        expect(bowlers[0].doubles_partner_id).to eq(bowlers[1].id)
        expect(bowlers[1].doubles_partner_id).to eq(bowlers[0].id)
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
    let(:bowler) { create(:bowler, person: create(:person), tournament: tournament) }
    let(:bowler_identifier) { bowler.identifier }

    let(:chosen_items) { [] }
    let(:purchasable_items) do
      chosen_items.map { |item| { identifier: item.identifier, quantity: 1} }
    end

    let(:purchase_identifiers) { bowler.purchases.unpaid.collect(&:identifier) }
    let(:expected_total) { 0 }
    let(:client_id) { tournament.paypal_client_id }
    let(:total_to_charge) { bowler.purchases.unpaid.sum(&:amount) + chosen_items.sum(&:value) }

    let(:expected_result) do
      {
        client_id: client_id,
        total_to_charge: total_to_charge,
      }
    end

    context 'a standard tournament' do
      let(:entry_fee_amount) { 117 }
      let(:early_discount_amount) { -13 }
      let(:late_fee_amount) { 24 }
      let(:tournament) { create :tournament, :active, :accepting_payments }
      let!(:entry_fee_item) { create(:purchasable_item, :entry_fee, value: entry_fee_amount, tournament: tournament) }
      let!(:early_discount_item) { create(:purchasable_item, :early_discount, value: early_discount_amount, tournament: tournament, configuration: { valid_until: 1.week.from_now }) }
      let!(:late_fee_item) { create(:purchasable_item, :late_fee, value: late_fee_amount, tournament: tournament, configuration: { applies_at: 2.weeks.ago }) }

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
          expect(json['total']).to eq(expected_total)
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
            expect(json['total']).to eq(expected_total)
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
            expect(json['total']).to eq(expected_total)
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
            expect(json['total']).to eq(expected_total)
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
              expect(json['total']).to eq(expected_total)
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
              expect(json['total']).to eq(expected_total)
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

    context 'a tournament with event selection' do
      let(:tournament) { create :tournament, :active, :accepting_payments, :with_event_selection }
      let!(:bundle_discount_item) { create :purchasable_item, :event_bundle_discount, tournament: tournament }

      let(:chosen_items) { [tournament.purchasable_items.event.first] }

      let(:expected_total) { tournament.purchasable_items.event.first.value }

      it 'returns an OK status code' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'returns the correct total' do
        subject
        expect(json['total']).to eq(expected_total)
      end

      it 'includes the expected paypal client id' do
        subject
        expect(json['paypal_client_id']).to eq(client_id)
      end

      context 'when a bundle discount applies' do
        let(:chosen_items) { tournament.purchasable_items.event }
        let(:expected_total) { tournament.purchasable_items.event.sum(&:value) + bundle_discount_item.value }

        it 'returns an OK status code' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'returns the correct total' do
          subject
          expect(json['total']).to eq(expected_total)
        end

        context 'already purchased one event, now purchasing the other to complete the bundle' do
          let(:chosen_items) { [tournament.purchasable_items.event.first] }
          let(:expected_total) { tournament.purchasable_items.event.first.value + bundle_discount_item.value }

          before { create :purchase, :paid, bowler: bowler, purchasable_item: tournament.purchasable_items.event.second }

          it 'returns an OK status code' do
            subject
            expect(response).to have_http_status(:ok)
          end

          it 'returns the correct total' do
            subject
            expect(json['total']).to eq(expected_total)
          end
        end
      end
    end
  end
end

