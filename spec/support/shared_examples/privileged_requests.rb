RSpec.shared_examples 'an authorized action' do
  context 'When the Authorization header is missing' do
    let(:auth_headers) { {} }

    it 'returns a 401 Unauthorized' do
      subject
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

RSpec.shared_examples 'for superusers only' do |success_response|
  context 'with a role of unpermitted' do
    let(:requesting_user) { create(:user) }

    it 'shall not pass' do
      subject
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'with a role of director' do
    let(:requesting_user) { create(:user, :director) }

    it 'shall not pass' do
      subject
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'with a role of superuser' do
    let(:requesting_user) { create(:user, :superuser) }

    it 'shall pass' do
      subject
      expect(response).to have_http_status(success_response)
    end
  end
end
