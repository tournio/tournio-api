# frozen_string_literal: true

# == Schema Information
#
# Table name: contacts
#
#  id                      :bigint           not null, primary key
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

FactoryBot.define do
  factory :contact do
  end
end
