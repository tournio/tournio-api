class Signup < ApplicationRecord
  include AASM

  belongs_to :bowler
  belongs_to :purchasable_item

  aasm do
    state :initial, initial: true
    state :requested
    state :paid

    event :request do
      transitions from: :initial, to: :requested
    end

    event :never_mind do
      transitions from: :requested, to: :initial
    end

    event :pay do
      transitions from: %i[initial requested], to: :paid
    end
  end
end
