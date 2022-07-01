require 'rails_helper'

RSpec.describe "StripeWebhooks", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/stripe_webhooks/create"
      expect(response).to have_http_status(:success)
    end
  end

end
