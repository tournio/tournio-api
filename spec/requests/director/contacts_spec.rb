require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::ContactsController, type: :request do
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

    let(:uri) { "/director/tournaments/#{tournament_identifier}/contacts" }

    let(:tournament) { create :tournament }
    let(:tournament_identifier) { tournament.identifier }

    let(:params) do
      {
        contact: new_contact_params,
      }
    end
    let(:new_contact_params) do
      {
        name: 'Contacty McContact',
        email: 'foo@foo.foo',
        role: 'director',
        notify_on_payment: false,
        notify_on_registration: true,
        notification_preference: 'daily_summary',
      }
    end

    ###############

    include_examples 'an authorized action'

    it 'succeeds with a 201 Created' do
      subject
      expect(response).to have_http_status(:created)
    end

    it 'return the created contact' do
      subject
      expect(json).to have_key('id')
    end

    it 'includes the new item in the response' do
      subject
      expect(json['name']).to eq('Contacty McContact')
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

    let(:uri) { "/director/contacts/#{contact_id}" }

    let(:tournament) { create :tournament }
    let(:contact) { create :contact, tournament: tournament, name: 'JoJo Rabbit', email: 'jojo@rabbit.org', role: :director }
    let(:contact_id) { contact.id }

    let(:params) do
      {
        contact: contact_params,
      }
    end
    let(:contact_params) do
      {
        notify_on_payment: false,
        notify_on_registration: true,
        notification_preference: 'individually',
      }
    end

    ###############

    include_examples 'an authorized action'

    it 'succeeds with a 200 OK' do
      subject
      expect(response).to have_http_status(:ok)
    end

    it 'return the created contact' do
      subject
      expect(json).to have_key('id')
    end

    it 'updates the contact correctly' do
      subject
      expect(contact.reload.notify_on_registration).to be_truthy
    end

    it 'updates the notification preference correctly' do
      subject
      expect(contact.reload.individually?).to be_truthy
    end

    it 'includes the contact in the response' do
      subject
      expect(json['name']).to eq('JoJo Rabbit')
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
      context 'an unrecognized contact identifier' do
        let(:contact_id) { 'say-what-now' }

        it 'yields a 404 Not Found' do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

end
