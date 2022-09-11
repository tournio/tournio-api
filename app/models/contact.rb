# frozen_string_literal: true

# == Schema Information
#
# Table name: contacts
#
#  id                      :bigint           not null, primary key
#  display_order           :integer
#  email                   :string
#  identifier              :string
#  name                    :string
#  notes                   :text
#  notification_preference :integer          default("daily_summary")
#  notify_on_payment       :boolean          default(FALSE)
#  notify_on_registration  :boolean          default(FALSE)
#  phone                   :string
#  role                    :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  tournament_id           :bigint
#
# Indexes
#
#  index_contacts_on_identifier     (identifier) UNIQUE
#  index_contacts_on_tournament_id  (tournament_id)
#

class Contact < ApplicationRecord
  belongs_to :tournament

  before_create :generate_identifier

  scope :registration_notifiable, -> { where(notify_on_registration: true) }
  scope :payment_notifiable, -> { where(notify_on_payment: true) }

  enum role: [
    :director,
    :secretary,
    :treasurer,
    :'secretary-treasurer',
    :statistician,
    :fundraising,
    :'co-director',
    :registration,
    :'igbo-representative',
    :technologist,
    :'member-at-large',
  ]
  enum notification_preference: [ :daily_summary, :individually ]

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end
end
