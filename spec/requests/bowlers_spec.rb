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

    let(:tournament) { create :tournament, :active, :with_a_bowling_event }
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

    let(:uri) { "/tournaments/#{tournament.identifier}/bowlers" }
    let(:tournament) { create :tournament, :active, :with_entry_fee, :with_additional_questions }

    context 'adding a bowler to a team' do
      let!(:team) { create :team, :standard_three_bowlers, tournament: tournament }
      let(:bowler_params) do
        {
          team_identifier: team.identifier,
          bowlers: [
            create_bowler_test_data.merge({
              position: 4,
            })
          ],
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

      it 'includes the team identifier in the response' do
        subject
        bowler = Bowler.last
        expect(json[0]['team_identifier']).to eq(team.identifier)
      end

      it 'creates an entry-fee purchase for the bowler' do
        subject
        bowler = Bowler.last
        expect(bowler.purchases.entry_fee).not_to be_empty
      end

      it 'creates a data point' do
        expect { subject }.to change(DataPoint, :count).by(1)
      end

      it 'creates the right kinds of data point' do
        subject
        dp = DataPoint.last
        expect(dp.key).to eq('registration_type')
        expect(dp.value).to eq('standard')
      end

      it 'does not assign a doubles partner by default' do
        subject
        expect(json[0]['doubles_partner']).to be_nil
      end

      context 'when a doubles partner identifier is specified' do
        let(:partner) { team.bowlers.last }
        let(:bowler_params) do
          {
            team_identifier: team.identifier,
            bowlers: [
              create_bowler_test_data.merge({
                position: 4,
                doubles_partner_identifier: partner.identifier
              })
            ],
          }
        end

        it 'assigns the partner correctly' do
          subject
          expect(json[0]['doubles_partner']['identifier']).to eq(partner.identifier)
        end

        it 'partners up the other two, since they were all that was left' do
          subject
          expect(team.bowlers[0].doubles_partner_id).to eq(team.bowlers[1].id)
        end

        it 'partners up the other two, from the other direction' do
          subject
          expect(team.bowlers[1].doubles_partner_id).to eq(team.bowlers[0].id)
        end
      end

      context "when two of the existing bowlers are partnered" do
        let!(:partner) { team.bowlers.last }

        before do
          team.bowlers.first.update(doubles_partner_id: team.bowlers.second.id)
          team.bowlers.second.update(doubles_partner_id: team.bowlers.first.id)
        end

        it 'partners up this bowler with the other unpartnered one' do
          subject
          new_bowler = Bowler.last
          expect(new_bowler.doubles_partner_id).to eq(partner.id)
        end

        it 'is reflected in the response' do
          subject
          expect(json[0]['doubles_partner']['identifier']).to eq(partner.identifier)
        end

        it 'is reciprocal' do
          subject
          new_bowler = Bowler.last
          expect(partner.reload.doubles_partner_id).to eq(new_bowler.id)
        end
      end

      context 'sneaking some trailing whitespace in on the email address' do
        before do
          bowler_params[:bowlers][0]['person_attributes']['email'] += ' '
        end

        it 'succeeds' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'trims the trailing whitespace from the incoming email address' do
          subject
          bowler = Bowler.last
          expect(bowler.email).to eq(bowler_params[:bowlers][0]['person_attributes']['email'].strip)
        end
      end

      context 'a tournament with event selection' do
        let(:tournament) { create :tournament, :active, :with_a_bowling_event, :with_additional_questions }
        let(:bowler_params) do
          {
            bowlers: [
              create_bowler_test_data,
            ],
          }
        end

        it 'succeeds' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'does not create any entry-fee purchases' do
          expect { subject }.not_to change(Purchase, :count)
        end
      end
    end

    context 'registering as an individual' do
      let(:bowler_params) do
        {
          bowlers: [
            create_bowler_test_data
          ],
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


      it 'creates a data point' do
        expect { subject }.to change(DataPoint, :count).by(1)
      end

      it 'creates a solo data point' do
        subject
        expect(DataPoint.last.value).to eq('solo')
      end


      context 'sneaking some trailing whitespace in on the email address' do
        before do
          bowler_params[:bowlers][0]['person_attributes']['email'] += ' '
        end

        it 'succeeds' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'trims the trailing whitespace from the incoming email address' do
          subject
          bowler = Bowler.last
          expect(bowler.email).to eq(bowler_params[:bowlers][0]['person_attributes']['email'].strip)
        end
      end

      context 'a tournament with event selection' do
        let(:tournament) { create :tournament, :active, :with_a_bowling_event, :with_additional_questions }
        let(:bowler_params) do
          {
            bowlers: [
              create_bowler_test_data,
            ],
          }
        end

        it 'succeeds' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'does not create any entry-fee purchases' do
          expect { subject }.not_to change(Purchase, :count)
        end
      end
    end

    context 'registering as a doubles pair' do
      let(:tournament) { create :tournament, :active, :with_a_bowling_event, :with_additional_questions }
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

      it 'creates a new_pair data point' do
        subject
        expect(DataPoint.last.value).to eq('new_pair')
      end
    end
  end

  describe '#show' do
    subject { get uri, as: :json }

    let(:uri) { "/bowlers/#{bowler.identifier}" }
    let(:tournament) { create :tournament, :active, :with_entry_fee }
    let(:bowler) { create :bowler, :with_team, tournament: tournament }

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
      expect(bowlerDeets).to have_key('amount_paid')
      expect(bowlerDeets).to have_key('unpaid_purchases')
      expect(bowlerDeets).to have_key('paid_purchases')
    end

    context 'a bowler with a nickname' do
      let(:person) { create :person, nickname: 'Gorgeous' }
      let(:bowler) { create :bowler, :with_team, tournament: tournament, person: person }

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
                                :with_extra_stuff }

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

      context 'when a purchasable item is disabled' do
        before do
          tournament.purchasable_items.raffle.update_all(enabled: false)
        end

        it 'excludes the disabled item' do
          subject
          item_keys = json['available_items'].keys
          raffle_identifier = tournament.purchasable_items.unscoped.raffle.first.identifier
          expect(item_keys).not_to include(raffle_identifier)
        end
      end
    end
  end
end

