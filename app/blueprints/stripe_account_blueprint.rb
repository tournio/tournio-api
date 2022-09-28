class StripeAccountBlueprint < Blueprinter::Base
  identifier :identifier
  fields :link_url, :link_expires_at
  field :can_accept_payments do |sa, _|
    sa.can_accept_payments?
  end
end
