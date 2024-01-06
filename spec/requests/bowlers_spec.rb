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

  describe '#commerce' do
    subject { get uri, as: :json }

    let(:uri) { "/bowlers/#{bowler.identifier}/commerce" }
    let(:tournament) do
      create :tournament,
        :active,
        :with_entry_fee
    end
    let(:entry_fee_item) { tournament.purchasable_items.entry_fee.first }
    let(:bowler) { create :bowler, tournament: tournament }

    it 'succeeds' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'includes bowler details' do
      subject
      expect(json).to have_key('bowler')
    end

    it 'includes a tournament property' do
      subject
      expect(json).to have_key('tournament')
    end

    it 'includes the basics of the tournament details' do
      subject
      expect(json['tournament'].keys).to include(*%w(identifier name year abbreviation imageUrl))
    end

    it 'includes a team property' do
      subject
      expect(json).to have_key('team')
    end

    it 'includes paid purchases' do
      subject
      expect(json).to have_key('purchases')
    end

    it 'includes available items' do
      subject
      expect(json).to have_key('availableItems')
    end

    it 'includes free entry' do
      subject
      expect(json).to have_key('freeEntry')
    end

    it 'includes automatic items' do
      subject
      expect(json).to have_key('automaticItems')
    end

    it 'includes signupables' do
      subject
      expect(json).to have_key('signupables')
    end

    it 'includes the bowler identifier' do
      subject
      expect(json['bowler']['identifier']).to eq(bowler.identifier)
    end

    #
    # base cases
    #
    it 'has zero available items' do
      subject
      expect(json['availableItems']).to be_empty
    end

    it 'has zero paid purchases' do
      subject
      expect(json['purchases']).to be_empty
    end

    it 'has zero signupables' do
      subject
      expect(json['signupables']).to be_empty
    end

    it 'has the entry fee as automatic' do
      subject
      expect(json['automaticItems'][0]['identifier']).to eq(entry_fee_item.identifier)
    end

    context 'when the bowler has a free entry' do
      let(:free_entry_code) { 'BOWLING-IS-LIFE' }
      let(:confirmed) { false }

      before do
        create :free_entry,
          unique_code: free_entry_code,
          confirmed: confirmed,
          bowler: bowler,
          tournament: tournament
      end

      it 'includes it' do
        subject
        expect(json['freeEntry']['uniqueCode']).to eq(free_entry_code)
      end

      context 'and it is not confirmed' do
        it 'has no automatic items' do
          subject
          expect(json['automaticItems']).to be_empty
        end
      end

      context 'and it is confirmed' do
        let(:confirmed) { true }

        it 'has no automatic items' do
          subject
          expect(json['automaticItems']).to be_empty
        end
      end
    end

    context 'with an entry fee purchase' do
      context 'that is paid' do
        before do
          create :purchase, :paid,
            bowler: bowler,
            purchasable_item: entry_fee_item,
            amount: entry_fee_item.value
        end


        it 'has the entry fee as the single paid purchase' do
          subject
          expect(json['purchases'].first['purchasableItem']['identifier']).to eq(entry_fee_item.identifier)
        end
      end
    end

    context 'when there is an early-registration discount' do
      let!(:early_discount_item) do
        create :purchasable_item,
          :early_discount,
          tournament: tournament
      end

      context 'and the tournament says it applies' do
        before do
          allow_any_instance_of(Tournament).to receive(:in_early_registration?).and_return(true)
        end

        it 'includes the discount item as automatic' do
          subject
          expect(json['automaticItems'].collect{ |ai| ai['identifier'] }).to include(early_discount_item.identifier)
        end
      end

      context 'and the tournament says it does not apply' do
        before do
          allow_any_instance_of(Tournament).to receive(:in_early_registration?).and_return(false)
        end

        it 'does not include the discount item as automatic' do
          subject
          expect(json['automaticItems'].collect{ |ai| ai['identifier'] }).not_to include(early_discount_item.identifier)
        end
      end
    end

    context 'when there is a late-registration charge' do
      let!(:late_fee_item) do
        create :purchasable_item,
          :late_fee,
          tournament: tournament
      end

      context 'but it does not apply yet' do
        before do
          allow_any_instance_of(Tournament).to receive(:in_late_registration?).and_return(false)
        end

        it 'does not include the discount in automatic items' do
          subject
          expect(json['automaticItems'].collect{ |ai| ai['identifier'] }).not_to include(late_fee_item.identifier)
        end
      end

      context 'and it applies' do
        before do
          allow_any_instance_of(Tournament).to receive(:in_late_registration?).and_return(true)
        end

        it 'includes the late-fee item as automatic' do
          subject
          expect(json['automaticItems'].collect{ |ai| ai['identifier'] }).to include(late_fee_item.identifier)
        end
      end
    end

    context 'when there are user-selectable purchasable items' do
      let(:tournament) do
        create :tournament,
          :active,
          :with_entry_fee,
          :with_scratch_competition_divisions, # scratch masters
          :with_an_optional_event,  # an optional event
          :with_extra_stuff         # raffle and banquet
      end

      before do
        tournament.purchasable_items.bowling.each do |pi|
          create :signup,
            bowler: bowler,
            purchasable_item: pi
        end
      end

      it 'includes an array of available items' do
        subject
        expect(json['availableItems']).to be_an_instance_of(Array)
      end

      it 'includes the expected number of available items' do
        subject
        expect(json['availableItems'].count).to eq(2)
      end

      it 'includes the correct available items' do
        subject
        item_identifiers = tournament.purchasable_items.banquet.collect(&:identifier) + tournament.purchasable_items.raffle.collect(&:identifier)
        json_identifiers = json['availableItems'].collect { |ai| ai['identifier'] }
        expect(json_identifiers).to match_array(item_identifiers)
      end

      it 'includes the expected number of signupables' do
        subject

        expect(json['signupables'].count).to eq(tournament.purchasable_items.bowling.count)
      end

      it 'includes the correct bowling items in signupables' do
        subject

        json_identifiers = json['signupables'].collect { |ai| ai['identifier'] }
        expect(json_identifiers).to match_array(tournament.purchasable_items.bowling.collect(&:identifier))
      end

      context 'and the bowler has signed up for one (but not paid)' do
        let(:bowling_item) do
          tournament.purchasable_items.bowling.where(refinement: nil).first
        end

        before do
          bowler.signups.find_by(purchasable_item_id: bowling_item.id).request!
        end

        it 'indicates the requested status in signupables' do
          subject

          json_item = json['signupables'].filter { |item| item['identifier'] == bowling_item.identifier }.first
          expect(json_item['status']).to eq('requested')
        end
      end

      context 'and the bowler has signed up for one (and paid)' do
        let(:bowling_item) do
          tournament.purchasable_items.bowling.where(refinement: nil).first
        end

        before do
          bowler.signups.find_by(purchasable_item_id: bowling_item.id).pay!
        end

        it 'indicates the requested status in signupables' do
          subject

          json_item = json['signupables'].filter { |item| item['identifier'] == bowling_item.identifier }.first
          expect(json_item['status']).to eq('paid')
        end
      end

      context 'and the bowler has bought a multi-use item, like a banquet ticket' do
        let(:banquet_item) { tournament.purchasable_items.banquet.first }

        before do
          create :purchase, :paid,
            bowler: bowler,
            purchasable_item: banquet_item,
            amount: banquet_item.value
        end

        it 'still includes the item in availableItems' do
          subject

          json_identifiers = json['availableItems'].collect { |ai| ai['identifier'] }
          expect(json_identifiers).to include(banquet_item.identifier)
        end

        it 'includes the one they bought in purchases' do
          subject

          json_identifiers = json['purchases'].collect { |p| p['purchasableItem']['identifier'] }
          expect(json_identifiers).to include(banquet_item.identifier)
        end
      end
    end

    context 'kitchen sink' do
      let(:tournament) do
        create :tournament,
          :active,
          :with_entry_fee,
          :with_scratch_competition_divisions, # scratch masters
          :with_an_optional_event,  # an optional event
          :with_extra_stuff         # raffle and banquet
      end
      let(:entry_fee_item) { tournament.purchasable_items.entry_fee.first }
      let(:late_fee_item) { tournament.purchasable_items.late_fee.first }
      let(:raffle_item) { tournament.purchasable_items.raffle.first }
      let(:bowling_item) { tournament.purchasable_items.bowling.division.first }
      let(:unbought_bowling_item) { tournament.purchasable_items.single_use.first }

      before do
        allow_any_instance_of(Tournament).to receive(:in_late_registration?).and_return(true)
        create :purchasable_item,
          :late_fee,
          tournament: tournament
      end

      context 'when the bowler has bought nothing' do
        it 'includes the entry fee item as automatic' do
          subject
          expect(json['automaticItems'].collect{ |ai| ai['identifier'] }).to include(entry_fee_item.identifier)
        end

        it 'includes the late-fee item as automatic' do
          subject
          expect(json['automaticItems'].collect{ |ai| ai['identifier'] }).to include(late_fee_item.identifier)
        end
      end

      context 'when the bowler has bought some things, including an entry fee and a late fee' do
        before do
          create :purchase, :paid,
            bowler: bowler,
            purchasable_item: entry_fee_item,
            amount: entry_fee_item.value
          create :purchase, :paid,
            bowler: bowler,
            purchasable_item: late_fee_item,
            amount: entry_fee_item.value
          create :purchase, :paid,
            bowler: bowler,
            purchasable_item: bowling_item,
            amount: bowling_item.value
          create :purchase, :paid,
            bowler: bowler,
            purchasable_item: raffle_item,
            amount: raffle_item.value
        end

        #####################
        # Automatic
        # ###################

        it 'excludes the entry fee as automatic' do
          subject
          expect(json['automaticItems'].collect{ |ai| ai['identifier'] }).not_to include(entry_fee_item.identifier)
        end

        it 'excludes the late-fee item as automatic' do
          subject
          expect(json['automaticItems'].collect{ |ai| ai['identifier'] }).not_to include(late_fee_item.identifier)
        end

        #######################
        # Purchases
        # #####################
        it 'contains purchases' do
          subject
          expect(json['purchases']).not_to be_empty
        end

        it 'has the entry fee in purchases' do
          subject
          json_identifiers = json['purchases'].collect { |p| p['purchasableItem']['identifier'] }
          expect(json_identifiers).to include(entry_fee_item.identifier)
        end

        it 'has the late fee in purchases' do
          subject
          json_identifiers = json['purchases'].collect { |p| p['purchasableItem']['identifier'] }
          expect(json_identifiers).to include(late_fee_item.identifier)
        end

        it 'includes the bowling item they bought in purchases' do
          subject
          json_identifiers = json['purchases'].collect { |p| p['purchasableItem']['identifier'] }
          expect(json_identifiers).to include(bowling_item.identifier)
        end

        it 'includes the raffle item they bought in purchases' do
          subject
          json_identifiers = json['purchases'].collect { |p| p['purchasableItem']['identifier'] }
          expect(json_identifiers).to include(raffle_item.identifier)
        end

        ##########################
        # Available items
        # ########################

        it 'excludes the bowling item they bought from availableItems' do
          subject

          json_identifiers = json['availableItems'].collect { |ai| ai['identifier'] }
          expect(json_identifiers).not_to include(bowling_item.identifier)
        end

        it 'includes the bowling item they did not buy in availableItems' do
          subject

          json_identifiers = json['availableItems'].collect { |ai| ai['identifier'] }
          expect(json_identifiers).not_to include(unbought_bowling_item.identifier)
        end

        it 'includes the raffle item in availableItems' do
          subject

          json_identifiers = json['availableItems'].collect { |ai| ai['identifier'] }
          expect(json_identifiers).to include(raffle_item.identifier)
        end
      end
    end

    #
    # when we support requesting items without paying for them...
    # --> Does not include entry fees
    #
    # it 'includes requested items' do
    #   subject
    #   expect(json).to have_key('requested_items')
    # end
  end

  describe '#stripe_checkout' do
    subject { post uri, params: checkout_params, as: :json }

    let(:uri) { "/bowlers/#{bowler_identifier}/stripe_checkout" }

    let(:checkout_params) do
      {
        automatic_items: automatic_items,
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

    let(:fees) { [] }
    let(:discounts) { [] }
    let(:automatic_items) { (fees + discounts).map(&:identifier) }

    let(:expected_total) { chosen_items.sum(&:value) + fees.sum(&:value) - fees.sum(&:value) }

    let(:stripe_response_url) { 'https://www.goldengateglassic.org' }
    let(:stripe_checkout_session_id) { 'stripe_checkout_session_abc123xyz789' }

    let(:expected_result) do
      {
        redirect_to: stripe_response_url,
        checkout_session_id: stripe_checkout_session_id,
      }
    end

    context 'a standard tournament' do
      let(:tournament) { create :tournament, :active }

      before do
        allow_any_instance_of(BowlersController).to receive(:create_stripe_checkout_session).and_return(
          {
            url: stripe_response_url,
            id: stripe_checkout_session_id,
          }
        )
      end

      context 'regular registration' do
        let(:entry_fee_amount) { 117 }
        let(:entry_fee_item) do
          create(
            :purchasable_item,
            :entry_fee,
            :with_stripe_product,
            value: entry_fee_amount,
            tournament: tournament
          )
        end
        let(:fees) do
          [entry_fee_item]
        end

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
          let(:early_discount_amount) { 13 }
          let(:early_discount_item) do
            create(
              :purchasable_item,
              :early_discount,
              :with_stripe_coupon,
              value: early_discount_amount,
              tournament: tournament,
            )
          end
          let(:discounts) { [early_discount_item] }

          it 'returns an OK status code' do
            subject
            expect(response).to have_http_status(:ok)
          end
        end

        context 'with late-registration fee' do
          let(:late_fee_amount) { 20 }
          let(:late_fee_item) do
            create(
              :purchasable_item,
              :late_fee,
              :with_stripe_product,
              value: late_fee_amount,
              tournament: tournament,
              configuration: { applies_at: 2.weeks.ago }
            )
          end
          let(:fees) do
            [
              entry_fee_item,
              late_fee_item,
            ]
          end

          it 'returns an OK status code' do
            subject
            expect(response).to have_http_status(:ok)
          end
        end

      end

      context 'with some chosen items' do
        let(:chosen_items) do
          [
            create(:purchasable_item, :scratch_competition, :with_stripe_product, tournament: tournament),
            create(:purchasable_item, :optional_event, :with_stripe_product, tournament: tournament),
          ]
        end

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

