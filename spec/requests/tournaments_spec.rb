require 'rails_helper'

describe TournamentsController, type: :request do
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end

  describe '#index' do
    subject { get uri, headers: headers }

    let(:uri) { '/tournaments' }

    let(:expected_keys) { %w(identifier name state status start_date location) }

    let!(:setup_tournament) { create :tournament }
    let!(:testing_tournament) { create :tournament, :testing }
    let!(:active_tournament) { create :tournament, :active }
    let!(:closed_tournament) { create :tournament, :closed }
    let!(:future_closed_tournament) { create :tournament, :future_closed }

    it 'returns an array' do
      subject
      expect(json).to be_instance_of(Array);
    end

    it 'limits the response to future tournaments that are either open or closed' do
      subject
      expect(json.length).to eq(2);
    end

    it 'has the required keys in each element' do
      subject
      expect(json[0].keys.intersection(expected_keys)).to match_array(expected_keys)
    end
  end

  describe '#show' do
    subject { get uri, headers: headers }

    let(:uri) { "/tournaments/#{tournament.identifier}" }

    let(:expected_keys) { %w(identifier name state status start_date location registration_deadline website year) }

    let(:tournament) { create :tournament, :active }

    it 'returns a tournament object' do
      subject
      expect(json.keys.intersection(expected_keys)).to match_array(expected_keys)
    end
  end
end
