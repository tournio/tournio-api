require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::PurchasableItemsController, type: :request do
  let(:requesting_user) { create(:user, :superuser) }
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers(headers, requesting_user) }

  describe '#create' do
    subject { post uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/tournaments/#{tournament_identifier}/purchasable_items" }

    let(:tournament) { create :tournament }
    let(:tournament_identifier) { tournament.identifier }

    let(:params) do
      {
        purchasable_items: [new_item_params],
      }
    end
    let(:new_item_params) do
      {
        category: category,
        determination: determination,
        name: 'A new purchasable item',
        value: 27,
        refinement: refinement,
        configuration: configuration_param,
      }
    end
    let(:category) { 'bowling' }
    let(:determination) { 'single_use' }
    let(:refinement) { '' }
    let(:configuration_param) do
      {
        order: 3,
        note: '',
      }
    end

    ###############

    include_examples 'an authorized action'

    it 'succeeds with a 201 Created' do
      subject
      expect(response).to have_http_status(:created)
    end

    it 'returns an array of created items' do
      subject
      expect(json).to be_a_kind_of(Array)
      expect(json.count).to eq(1)
    end

    it 'includes the new item in the response' do
      subject
      expect(json.first).to have_key('identifier')
    end

    it 'kicks off a Stripe::ProductCreator job' do
      expect(Stripe::ProductCreator).to receive(:perform_in).once
      subject
    end

    it 'does not kick off a Stripe::CouponCreator job' do
      expect(Stripe::CouponCreator).not_to receive(:perform_in)
      subject
    end

    context 'a collection of division items' do
      let(:category) { 'bowling' }
      let(:determination) { 'single_use' }
      let(:refinement) { 'division' }

      let(:params) do
        {
          purchasable_items: %w(A B C D E).collect do |div|
            {
              category: category,
              determination: determination,
              refinement: refinement,
              name: 'A Division Item',
              value: 29,
              configuration: {
                division: div,
              },
            }
          end
        }
      end

      it 'succeeds with a 201 Created' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'returns an array of created items' do
        subject
        expect(json).to be_a_kind_of(Array)
        expect(json.count).to eq(5)
      end

      it 'kicks off a Stripe::ProductCreator job for each item' do
        expect(Stripe::ProductCreator).to receive(:perform_in).exactly(5).times
        subject
      end

      it 'does not kick off a Stripe::CouponCreator job' do
        expect(Stripe::CouponCreator).not_to receive(:perform_in)
        subject
      end
    end

    context 'an event item' do
      let(:refinement) { 'single' }

      it 'succeeds' do
        subject
        expect(json.first).to have_key('identifier')
      end
    end

    context 'a ledger item' do
      let(:category) { 'ledger' }

      context 'entry fee' do
        let(:determination) { 'entry_fee' }
        let(:configuration_param) do
          {
            order: '',
            note: '',
          }
        end

        it 'succeeds with a 201 Created' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'kicks off a Stripe::ProductCreator job' do
          expect(Stripe::ProductCreator).to receive(:perform_in).once
          subject
        end

        it 'does not kick off a Stripe::CouponCreator job' do
          expect(Stripe::CouponCreator).not_to receive(:perform_in)
          subject
        end

        context 'when an entry fee already exists' do
          before { create :purchasable_item, :entry_fee, tournament: tournament }

          it 'fails with a Conflict' do
            subject
            expect(response).to have_http_status(:conflict)
          end

          it 'does not kick off a Stripe::ProductCreator job' do
            expect(Stripe::ProductCreator).not_to receive(:perform_in)
            subject
          end

          it 'does not kick off a Stripe::CouponCreator job' do
            expect(Stripe::CouponCreator).not_to receive(:perform_in)
            subject
          end
        end
      end

      context 'late registration fee' do
        let(:determination) { 'late_fee' }
        let(:configuration_param) do
          {
            applies_at: (Time.zone.now + 3.months).strftime("%FT%T%:z"),
            order: '',
            note: '',
          }
        end

        it 'succeeds with a 201 Created' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'kicks off a Stripe::ProductCreator job' do
          expect(Stripe::ProductCreator).to receive(:perform_in).once
          subject
        end

        it 'does not kick off a Stripe::CouponCreator job' do
          subject
          expect(Stripe::CouponCreator.jobs.size).to eq(0)
        end

        context 'without providing an applies_at timestamp' do
          let(:configuration_param) do
            {
              applies_at: '',
              order: '',
              note: '',
            }
          end

          it 'fails with unprocessable entity' do
            subject
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it 'does not kick off a Stripe::ProductCreator job' do
            expect(Stripe::ProductCreator).not_to receive(:perform_in)
            subject
          end

          it 'does not kick off a Stripe::CouponCreator job' do
            expect(Stripe::CouponCreator).not_to receive(:perform_in)
            subject
          end
        end

        context 'when a late fee already exists' do
          before { create :purchasable_item, :late_fee, tournament: tournament }

          it 'fails with a Conflict' do
            subject
            expect(response).to have_http_status(:conflict)
          end

          it 'does not kick off a Stripe::ProductCreator job' do
            expect(Stripe::ProductCreator).not_to receive(:perform_in)
            subject
          end

          it 'does not kick off a Stripe::CouponCreator job' do
            expect(Stripe::CouponCreator).not_to receive(:perform_in)
            subject
          end
        end
      end

      context 'early registration discount' do
        let(:determination) { 'early_discount' }
        let(:configuration_param) do
          {
            valid_until: (Time.zone.now + 3.months).strftime("%FT%T%:z"),
            order: '',
            note: '',
          }
        end

        it 'succeeds with a 201 Created' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'does not kick off a Stripe::ProductCreator job' do
          expect(Stripe::ProductCreator).not_to receive(:perform_in)
          subject
        end

        it 'kicks off a Stripe::CouponCreator job' do
          expect(Stripe::CouponCreator).to receive(:perform_in).once
          subject
        end

        context 'without providing a valid_until timestamp' do
          let(:configuration_param) do
            {
              valid_until: '',
              order: '',
              note: '',
            }
          end

          it 'fails with unprocessable entity' do
            subject
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it 'does not kick off a Stripe::ProductCreator job' do
            expect(Stripe::ProductCreator).not_to receive(:perform_in)
            subject
          end

          it 'does not kick off a Stripe::CouponCreator job' do
            expect(Stripe::CouponCreator).not_to receive(:perform_in)
            subject
          end
        end

        context 'when a discount already exists' do
          before { create :purchasable_item, :early_discount, tournament: tournament }

          it 'fails with a Conflict' do
            subject
            expect(response).to have_http_status(:conflict)
          end

          it 'does not kick off a Stripe::ProductCreator job' do
            expect(Stripe::ProductCreator).not_to receive(:perform_in)
            subject
          end

          it 'does not kick off a Stripe::CouponCreator job' do
            expect(Stripe::CouponCreator).not_to receive(:perform_in)
            subject
          end
        end
      end

      context 'an event bundle discount' do
        let(:determination) { 'bundle_discount' }
        let(:event1) { create :purchasable_item, :bowling_event, tournament: tournament }
        let(:event2) { create :purchasable_item, :bowling_event, tournament: tournament }
        let(:configuration_param) do
          {
            events: [event1.identifier, event2.identifier],
          }
        end

        it 'succeeds' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'includes the events in the created item' do
          subject
          expect(json[0]['configuration']['events']).to match_array([event1.identifier, event2.identifier])
        end
      end

      context 'an event-linked late fee' do
        let(:determination) { 'late_fee' }
        let(:refinement) { 'event_linked' }
        let(:event) { create :purchasable_item, :bowling_event, tournament: tournament }
        let(:configuration_param) do
          {
            event: event.identifier,
            applies_at: 2.weeks.from_now.strftime("%FT%T%:z")
          }
        end

        it 'succeeds' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'includes the event in the created item' do
          subject
          expect(json[0]['configuration']['event']).to eq(event.identifier)
        end

        it 'includes the applies_at in the created item' do
          subject
          expect(json[0]['configuration']).to have_key('applies_at')
        end

        it 'kicks off a Stripe::ProductCreator job' do
          expect(Stripe::ProductCreator).to receive(:perform_in).once
          subject
        end

        it 'does not kick off a Stripe::CouponCreator job' do
          expect(Stripe::CouponCreator).not_to receive(:perform_in)
          subject
        end
      end
    end

    context 'a banquet item' do
      let(:category) { 'banquet' }
      let(:determination) { 'multi_use' }
      let(:configuration_param) do
        {
          order: 1,
          note: '',
        }
      end

      it 'succeeds with a 201 Created' do
        subject
        expect(response).to have_http_status(:created)
      end
    end

    context 'a product item' do
      let(:category) { 'product' }
      let(:determination) { 'general' }
      let(:configuration_param) do
        {
          order: 1,
          note: 'A nice souvenir!'
        }
      end

      it 'succeeds with a 201 Created' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'kicks off a Stripe::ProductCreator job' do
        expect(Stripe::ProductCreator).to receive(:perform_in).once
        subject
      end

      it 'does not kick off a Stripe::CouponCreator job' do
        expect(Stripe::CouponCreator).not_to receive(:perform_in)
        subject
      end

      context 'an apparel product' do
        let(:determination) { 'apparel' }
        let(:size_params) do
          {
            size: 'one_size_fits_all',
          }
        end
        let(:configuration_param) do
          {
            order: 3,
            note: 'A good fit!',
          }.merge(size_params)
        end

        it 'succeeds with a 201 Created' do
          subject
          expect(response).to have_http_status(:created)
        end

        it 'includes the size property with the resulting product' do
          subject
          expect(json.first['configuration']).to have_key('size')
        end

        it 'includes the size value' do
          subject
          expect(json.first['configuration']['size']).to eq('one_size_fits_all')
        end

        it 'does not include a parent identifier' do
          subject
          expect(json.first['configuration']).not_to have_key('parent_identifier')
        end

        it 'does not set the refinement property' do
          subject
          expect(json.first['refinement']).not_to be_present
        end

        context 'with multiple sizes' do
          let(:refinement) { 'sized' }
          let(:size_params) do
            {
              sizes: {
                men: {
                  s: true,
                  m: true,
                  l: true,
                },
              }
            }
          end

          it 'returns a PI for each size, plus a parent one' do
            subject
            expect(json.size).to eq(size_params[:sizes][:men].size + 1)
          end

          it 'identifies one of the new PIs as the parent' do
            subject
            has_one_parent = json.one? { |jpi| jpi['refinement'] == 'sized' }
            expect(has_one_parent).to be_truthy
          end

          it 'does not include the refinement property on the other ones' do
            subject
            unrefined = json.select { |jpi| !jpi['refinement'].present? }
            expect(unrefined.count).to eq(size_params[:sizes][:men].size)
          end

          it 'identifies the parent on the other ones' do
            subject

            parent_index = json.index { |jpi| jpi['refinement'] == 'sized' }
            parent = json.at(parent_index)
            parent_identifier = parent['identifier']

            json.each_index do |i|
              next if i == parent_index
              jpi = json[i]
              expect(jpi['configuration']['parent_identifier']).to eq(parent_identifier)
            end
          end

          it 'includes a size on the other ones' do
            subject

            parent_index = json.index { |jpi| jpi['refinement'] == 'sized' }

            json.each_index do |i|
              next if i == parent_index
              jpi = json[i]
              expect(jpi['configuration']['size']).not_to be_nil
            end
          end

          it 'excludes the sizes property from the parent' do
            subject
            parent_index = json.index { |jpi| jpi['refinement'] == 'sized' }
            expect(json[parent_index]['configuration']['sizes']).to be_nil
          end
        end
      end
    end

    # Come back to this one when we bring in support for the Raffle category
    context 'a product item with denomination refinement' do
      let(:category) { 'product' }
      let(:determination) { 'multi_use' }
      let(:refinement) { 'denomination' }
      let(:configuration_param) do
        {
          order: 2,
          note: 'Available for pre-purchase only',
          denomination: '237 of the thing',
        }
      end

      it 'succeeds with a 201 Created' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'kicks off a Stripe::ProductCreator job' do
        expect(Stripe::ProductCreator).to receive(:perform_in).once
        subject
      end

      it 'does not kick off a Stripe::CouponCreator job' do
        expect(Stripe::CouponCreator).not_to receive(:perform_in)
        subject
      end

      context 'without providing a denomination' do
        let(:configuration_param) do
          {
            order: 3,
            note: 'A special item',
            denomination: '',
          }
        end

        it 'fails with unprocessable entity' do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'kicks off a Stripe::ProductCreator job' do
          expect(Stripe::ProductCreator).not_to receive(:perform_in)
          subject
        end

        it 'does not kick off a Stripe::CouponCreator job' do
          expect(Stripe::CouponCreator).not_to receive(:perform_in)
          subject
        end
      end
    end

    context 'an active tournament' do
      let(:tournament) { create :tournament, :active }

      it 'is forbidden' do
        subject
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'as an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'as a director' do
      let(:requesting_user) { create(:user, :director) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'associated with this tournament' do
        let(:requesting_user) { create :user, :director, tournaments: [tournament] }

        it 'shall pass' do
          subject
          expect(response).to have_http_status(:created)
        end
      end
    end

    context 'error scenarios' do
      context 'an unrecognized tournament identifier' do
        let(:tournament_identifier) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#update' do
    subject { patch uri, headers: auth_headers, params: params, as: :json }

    let(:uri) { "/director/purchasable_items/#{purchasable_item_id}" }

    let(:tournament_identifier) { tournament.identifier }
    let(:tournament) { create :tournament }
    let(:purchasable_item) { create :purchasable_item, :entry_fee, tournament: tournament }
    let(:purchasable_item_id) { purchasable_item.identifier }

    let(:other_params) { {} }
    let(:configuration_param) do
      {
        order: '',
        applies_at: '',
        valid_until: '',
        division: '',
        note: '',
        denomination: '',
      }
    end
    let(:params) do
      {
        purchasable_item: {
          value: 99,
          configuration: configuration_param,
        }.merge(other_params)
      }
    end

    include_examples 'an authorized action'

    it 'succeeds with a 200 OK' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'kicks off a Stripe::ProductUpdater job' do
      expect(Stripe::ProductUpdater).to receive(:perform_in).once
      subject
    end

    context 'when skip_stripe is true' do
      before do
        tournament.config_items << ConfigItem.new(key: 'skip_stripe', value: 'true')
      end

      it 'does not try to update the associated StripeProduct if skip_stripe is true' do
        expect(Stripe::ProductUpdater).not_to receive(:perform_in)
        subject
      end
    end

    context 'early discount' do
      let(:purchasable_item) { create :purchasable_item, :early_discount, tournament: tournament }
      let(:configuration_param) do
        {
          order: '',
          applies_at: '',
          valid_until: (Time.zone.now + 2.weeks).strftime("%FT%T%:z"),
          division: '',
          note: '',
          denomination: '',
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'does not kick off a Stripe::ProductUpdater job' do
        expect(Stripe::ProductUpdater).not_to receive(:perform_in)
        subject
      end
    end

    context 'late fee' do
      let(:purchasable_item) { create :purchasable_item, :late_fee, tournament: tournament }
      let(:configuration_param) do
        {
          order: '',
          applies_at: (Time.zone.now + 6.weeks).strftime("%FT%T%:z"),
          valid_until: '',
          division: '',
          note: '',
          denomination: '',
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'a bowling event' do
      let(:purchasable_item) { create :purchasable_item, :optional_event, tournament: tournament }
      let(:configuration_param) do
        {
          order: 5,
          applies_at: '',
          valid_until: '',
          division: '',
          note: '',
          denomination: '',
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'a division-based bowling event' do
      let(:purchasable_item) { create :purchasable_item, :scratch_competition, tournament: tournament }
      let(:configuration_param) do
        {
          order: '',
          applies_at: '',
          valid_until: '',
          division: 'B',
          note: '170-189',
          denomination: '',
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'a banquet entry' do
      let(:purchasable_item) { create :purchasable_item, :banquet_entry, tournament: tournament }
      let(:configuration_param) do
        {
          order: '',
          applies_at: '',
          valid_until: '',
          division: '',
          note: '',
          denomination: '',
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'a raffle ticket bundle' do
      let(:purchasable_item) { create :purchasable_item, :raffle_bundle, tournament: tournament }
      let(:configuration_param) do
        {
          order: 3,
          applies_at: '',
          valid_until: '',
          division: '',
          note: 'Nice.',
          denomination: '69 tickets',
        }
      end

      it 'succeeds with a 200 OK' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context 'an apparel item' do
      let(:purchasable_item) { create :purchasable_item, :apparel, :one_size_fits_all, tournament: tournament }

      context 'an apparel product' do
        let(:configuration_param) do
          {
            order: 3,
            note: 'A good fit!',
            size: 'one_size_fits_all',
          }
        end
        let(:other_params) do
          {
            name: 'A corrected name',
          }
        end

        it 'succeeds with a 200 OK' do
          subject
          expect(response).to have_http_status(:ok)
        end

        it 'returns a singleton item in the response' do
          subject
          expect(json).to have_key('identifier')
        end

        # We require that a size property be sent up with an update request.
        it 'includes the size property with the resulting product' do
          subject
          expect(json['configuration']).to have_key('size')
        end

        it 'includes the size value' do
          subject
          expect(json['configuration']['size']).to eq('one_size_fits_all')
        end

        it 'includes the updated name value' do
          subject
          expect(json['name']).to eq(other_params[:name])
        end

        it 'does not include a parent identifier' do
          subject
          expect(json['configuration']).not_to have_key('parent_identifier')
        end

        it 'still has an empty refinement property' do
          subject
          expect(json['refinement']).not_to be_present
        end

        context 'with multiple sizes' do
          let(:purchasable_item) { create :purchasable_item, :apparel, :sized, tournament: tournament }

          let(:configuration_param) do
            {
              order: 1,
              note: 'A playful shirt',
              sizes: {
                infant: {
                  newborn: true,
                  m12: true,
                  m24: true,
                },
              },
            }
          end

          it 'returns a PI for each size, plus a parent one' do
            subject
            expect(json.size).to eq(configuration_param[:sizes][:infant].size + 1)
          end

          it 'identifies one of the new PIs as the parent' do
            subject
            has_one_parent = json.one? { |jpi| jpi['refinement'] == 'sized' }
            expect(has_one_parent).to be_truthy
          end

          it 'does not include the refinement property on the other ones' do
            subject
            unrefined = json.select { |jpi| !jpi['refinement'].present? }
            expect(unrefined.count).to eq(configuration_param[:sizes][:infant].size)
          end

          it 'identifies the parent on the other ones' do
            subject

            parent_index = json.index { |jpi| jpi['refinement'] == 'sized' }
            parent = json.at(parent_index)
            parent_identifier = parent['identifier']

            json.each_index do |i|
              next if i == parent_index
              jpi = json[i]
              expect(jpi['configuration']['parent_identifier']).to eq(parent_identifier)
            end
          end

          it 'includes a size on the other ones' do
            subject

            parent_index = json.index { |jpi| jpi['refinement'] == 'sized' }

            json.each_index do |i|
              next if i == parent_index
              jpi = json[i]
              expect(jpi['configuration']['size']).not_to be_nil
            end
          end

          it 'excludes the sizes property from the parent' do
            subject
            parent_index = json.index { |jpi| jpi['refinement'] == 'sized' }
            expect(json[parent_index]['configuration']['sizes']).to be_nil
          end

          it 'has new identifiers on all the children' do
            originals = purchasable_item.children.collect(&:identifier)
            subject
            expect(json.collect { |pi| pi['identifier'] }.reject { |pi| pi['identifier'] == purchasable_item.identifier }).not_to match_array(originals)
          end
        end
      end
    end

    context 'an active tournament' do
      let(:tournament) { create :tournament, :active }

      it 'prevents updates' do
        subject
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'as an unpermitted user' do
      let(:requesting_user) { create(:user, :unpermitted) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'as a director' do
      let(:requesting_user) { create(:user, :director) }

      it 'shall not pass' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end

      context 'associated with this tournament' do
        let(:requesting_user) { create :user, :director, tournaments: [tournament] }

        it 'shall pass' do
          subject
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'error scenarios' do
      context 'an unrecognized purchasable item id' do
        let(:purchasable_item_id) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete uri, headers: auth_headers, as: :json }

    let(:uri) { "/director/purchasable_items/#{purchasable_item_id}" }

    let(:tournament) { create :tournament }
    let(:tournament_identifier) { tournament.identifier }
    let(:purchasable_item) { create :purchasable_item, :entry_fee, tournament: tournament }
    let(:purchasable_item_id) { purchasable_item.identifier }

    include_examples 'an authorized action'

    context 'an unrecognized item identifier' do
      let(:purchasable_item_id) { 'i-dont-know-her' }

      it 'responds with a Not Found' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'Tournament modes' do
      context 'Setup' do
        it 'responds with No Content' do
          subject
          expect(response).to have_http_status(:no_content)
        end

        it 'destroys the item' do
          subject
          begin
            purchasable_item.reload
          rescue => exception
          ensure
            expect(exception).to be_instance_of ActiveRecord::RecordNotFound
          end
        end
      end

      context 'Testing' do
        let(:tournament) { create :tournament, :testing }

        it 'responds with No Content' do
          subject
          expect(response).to have_http_status(:no_content)
        end

        it 'destroys the item' do
          subject
          begin
            purchasable_item.reload
          rescue => exception
          ensure
            expect(exception).to be_instance_of ActiveRecord::RecordNotFound
          end
        end
      end

      context 'Active' do
        let(:tournament) { create :tournament, :active }

        it 'responds with Forbidden' do
          subject
          expect(response).to have_http_status(:forbidden)
        end

        it 'does not destroy the item' do
          subject
          expect(purchasable_item.reload).not_to be_nil
        end
      end

      context 'Closed' do
        let(:tournament) { create :tournament, :closed }

        it 'responds with No Content' do
          subject
          expect(response).to have_http_status(:no_content)
        end

        it 'destroys the item' do
          subject
          begin
            purchasable_item.reload
          rescue => exception
          ensure
            expect(exception).to be_instance_of ActiveRecord::RecordNotFound
          end
        end
      end
    end
  end
end
