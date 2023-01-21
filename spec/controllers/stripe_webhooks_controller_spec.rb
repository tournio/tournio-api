require 'rails_helper'

RSpec.describe StripeWebhooksController, type: :controller do
  let(:headers) do
    {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  end

  describe "#webhook" do
    subject do
      request.headers.merge!(headers)
      post :webhook
    end

    let(:event_type) { 'something.unfamiliar' }
    let(:mock_event) do
      {
        id: "evt_thisIsNotARealEvent2022",
        account: "acct_thisIsAFakeAccount2022",
        type: event_type,
      }
    end

    before do
      allow(controller).to receive(:build_stripe_event).and_return(mock_event)
    end

    it "succeeds" do
      subject
      expect(response).to have_http_status(:no_content)
    end

    it "does not try to kick off a background job" do
      expect(controller).not_to receive(:event_to_class)
      subject
    end

    context 'for a checkout.session.completed event' do
      let(:event_type) { 'checkout.session.completed' }

      it "succeeds" do
        subject
        expect(response).to have_http_status(:no_content)
      end

      it "hands the work off to a background job" do
        expect(Stripe::CheckoutSessionCompleted).to receive(:perform_async)
        subject
      end
    end

    context 'for an account.updated event' do
      let(:event_type) { 'account.updated' }

      it "succeeds" do
        subject
        expect(response).to have_http_status(:no_content)
      end

      it "hands the work off to a background job" do
        expect(Stripe::AccountUpdated).to receive(:perform_async)
        subject
      end
    end

    context 'for a charge.refunded event' do
      let(:event_type) { 'charge.refunded' }

      it "succeeds" do
        subject
        expect(response).to have_http_status(:no_content)
      end

      it "hands the work off to a background job" do
        expect(Stripe::ChargeRefunded).to receive(:perform_async)
        subject
      end
    end
  end
end

