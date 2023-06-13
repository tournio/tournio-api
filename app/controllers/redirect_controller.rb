class RedirectController < ActiveStorage::Blobs::RedirectController

  # We do this because ActiveStorage's implementation lets the RecordNotFound error bubble up,
  # which writes a stack trace to the log and sends it to Bugsnag. But.. it's a not found.
  # Doesn't merit that much noise.
  rescue_from ActiveRecord::RecordNotFound do |err|
    Rails.logger.warn "Did not find a record."
    render json: nil, status: :not_found
  end
end
