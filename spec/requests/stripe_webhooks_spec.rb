require 'rails_helper'

RSpec.describe "StripeWebhooks", type: :request do
  describe "POST /stripe_webhook" do
    it "returns http success" do
      post "/stripe_webhook"
      expect(response).to have_http_status(:success)
    end
  end
end
