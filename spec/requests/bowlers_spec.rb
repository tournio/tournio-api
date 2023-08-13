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

    let(:tournament) { create :tournament, :active, :one_shift, :with_a_bowling_event }
    let(:tournament_identifier) { tournament.identifier }
    let(:uri) { "/tournaments/#{tournament_identifier}/bowlers" }

    before do
      10.times do |i|
        create :bowler, tournament: tournament, position: nil, shift: tournament.shifts.first
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

    let(:tournament) { create :tournament, :active, :with_entry_fee, :one_shift }
    let(:shift) { tournament.shifts.first }

    before do
      comment = create(:extended_form_field, :comment)
      pronouns = create(:extended_form_field, :pronouns)
      standings = create(:extended_form_field, :standings_link)

      create(:additional_question, extended_form_field: comment, tournament: tournament)
      create(:additional_question, extended_form_field: pronouns, tournament: tournament)
      create(:additional_question, extended_form_field: standings, tournament: tournament)
    end

    context 'joining a team on a standard tournament' do
      let(:uri) { "/tournaments/#{tournament.identifier}/bowlers" }
      let(:requested_position) { 4 }

      context 'with valid bowler input' do
        let(:bowler_params) do
          {
            team_identifier: team.identifier,
            bowlers: [create_bowler_test_data.merge({ position: requested_position })]
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

          context 'when the requested position is available' do
            # has positions 1 and 2 assigned
            let(:team) { create(:team, :standard_two_bowlers, tournament: tournament) }

            it 'assigns them to that position' do
              subject
              bowler = Bowler.find_by(identifier: json[0]['identifier'])
              expect(bowler.position).to eq(requested_position)
            end
          end

          context 'when the requested position is not available' do
            # has positions 1 and 2 assigned
            let(:team) { create(:team, :standard_two_bowlers, tournament: tournament) }
            let(:requested_position) { 1 }

            it 'assigns them the first open one' do
              subject
              bowler = Bowler.find_by(identifier: json[0]['identifier'])
              expect(bowler.position).to eq(3)
            end
          end

          it 'creates a join_team data point' do
            subject
            expect(DataPoint.last.value).to eq('join_team')
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

          context 'a team on a shift' do
            let(:bowler_params) do
              {
                bowlers: [
                  create_bowler_test_data.merge({ position: 4, shift_identifier: shift.identifier })
                ]
              }
            end

            before do
              team.bowlers.each do |b|
                create :bowler_shift, shift: shift, bowler: b
              end
            end

            it 'creates a BowlerShift instance' do
              expect { subject }.to change(BowlerShift, :count).by(1)
            end

            it 'bumps the requested count by one' do
              expect { subject }.to change { shift.reload.requested }.by(1)
            end

            it 'does not bump the confirmed count' do
              expect { subject }.not_to change { shift.reload.confirmed }
            end
          end

          context 'a team with zero bowlers' do
            let(:bowler_params) do
              {
                bowlers: [
                  create_bowler_test_data.merge({ position: 1, shift_identifier: shift.identifier })
                ]
              }
            end

            it 'creates a BowlerShift instance' do
              expect { subject }.to change(BowlerShift, :count).by(1)
            end

            it 'bumps the requested count by one' do
              expect { subject }.to change { shift.reload.requested }.by(1)
            end

            it 'does not bump the confirmed count' do
              expect { subject }.not_to change { shift.reload.confirmed }
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
          bowlers: [
            create_bowler_test_data.merge({ shift_identifier: shift.identifier })
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

      it 'creates a BowlerShift join model instance' do
        expect { subject }.to change(BowlerShift, :count).by(1)
      end

      it 'marks the BowlerShift as requested' do
        subject
        expect(BowlerShift.last.requested?).to be_truthy
      end

      it 'creates a data point' do
        expect { subject }.to change(DataPoint, :count).by(1)
      end

      it 'creates a solo data point' do
        subject
        expect(DataPoint.last.value).to eq('solo')
      end

      context "a tournament with two shifts" do
        let(:tournament) { create :tournament, :active, :with_entry_fee, :two_shifts }
        let(:shift) { tournament.shifts.second }

        it 'puts the bowler on the preferred shift' do
          subject
          bowler = Bowler.last
          expect(bowler.shift.id).to eq(shift.id)
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
        let(:tournament) { create :tournament, :active, :with_a_bowling_event }
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

          it 'creates a partner data point' do
            subject
            expect(DataPoint.last.value).to eq('partner')
          end
        end
      end
    end

    context 'registering as a doubles pair' do
      let(:tournament) { create :tournament, :active, :with_a_bowling_event, :one_shift }
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
      expect(bowlerDeets).to have_key('amount_billed')
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

