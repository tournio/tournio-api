module StripeApiHelpers
  def mock_event
    {
      created: Time.zone.now.to_i,
    }
  end
end
