require 'rails_helper'

RSpec.describe "Signups", type: :request do
  describe "GET /update" do
    it "returns http success" do
      get "/signups/update"
      expect(response).to have_http_status(:success)
    end
  end

end
