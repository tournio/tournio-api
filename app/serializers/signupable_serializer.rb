# frozen_string_literal: true

class SignupableSerializer < PurchasableItemSerializer
  attribute :signup_status do |pi|
    params[:signup].aasm_state
  end

  attribute :signup_identifier do |pi|
    params[:signup].identifier
  end
end
