# frozen_string_literal: true

class SignupableSerializer < PurchasableItemSerializer
  attribute :signup_status do |pi|
    params[:signup].aasm_state
  end

  attribute :signup_identifier do |pi|
    params[:signup].identifier
  end

  # if the pi is a division item, it should know if one of its sibling items is signed up
  attribute :sibling_signed_up do |pi|
    pi.division? && has_signed_up_sibling(params[:signup])
  end

  def has_signed_up_sibling(signup)
    pi = signup.purchasable_item

    sibling_pis = pi.tournament.purchasable_items.division.where(name: pi.name).where.not(identifier: pi.identifier)
    sibling_signups = signup.bowler.signups.where(purchasable_item: sibling_pis)

    sibling_signups.any? { |s| s.paid? || s.requested? }
  end
end
