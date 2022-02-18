require 'rails_helper'
require 'devise/jwt/test_helpers'

describe Director::TournamentsController, type: :request do
  let(:requesting_user) { create(:user, :superuser) }
  let(:auth_headers) { Devise::JWT::TestHelpers.auth_headers({}, requesting_user) }

  describe '#index' do
    subject { get uri, headers: auth_headers }

    let(:uri) { '/director/tournaments' }

    let!(:setup_tournament) { create :tournament }
    let!(:testing_tournament) { create :tournament, :testing }
    let!(:active_tournament) { create :tournament, :active }
    let!(:closed_tournament) { create :tournament, :closed }

    include_examples 'an authorized action'

    it 'returns an array' do
      subject
      expect(json).to be_instance_of(Array);
    end

    it 'includes all tournaments in the response' do
      subject
      expect(json.length).to eq(4);
    end

    context 'When all I need is upcoming tournaments' do
      let(:uri) { '/director/tournaments?upcoming=true' }

      it 'excludes past tournaments' do
        subject
        expect(json.length).to eq(3);
      end
    end

    context 'When I am a tournament director' do
      let(:requesting_user) { create(:user, :director, tournaments: my_tournaments) }
      let(:my_tournaments) { [testing_tournament, active_tournament] }

      it 'includes just my tournaments in the response' do
        subject
        expect(json.length).to eq(2);
      end

      context 'with no active tournaments' do
        let(:my_tournaments) { [] }

        it 'returns an empty array' do
          subject
          expect(json).to be_empty
        end
      end
    end

  end

  describe '#show' do

  end

  describe '#clear_test_data' do

  end

  describe '#state_change' do

  end

  describe '#csv_download' do

  end

  describe '#igbots_download' do

  end
end
