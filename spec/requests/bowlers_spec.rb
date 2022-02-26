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
end

