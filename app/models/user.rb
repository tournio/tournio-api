# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  identifier             :string
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("unpermitted"), not null
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_identifier            (identifier) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Allowlist

  devise :database_authenticatable,
         :recoverable,
         # :rememberable,
         :validatable,
         :trackable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

  enum role: %i[unpermitted director superuser]

  has_and_belongs_to_many :tournaments
  has_and_belongs_to_many :tournament_orgs

  before_create :generate_identifier

  def jwt_payload
    {
      'identifier' => identifier,
      'role' => role.to_s,
      'tournaments' => tournaments.pluck(:identifier)
    }
  end

  # notification is a symbol; trigger the reset-email if it's :reset_password_instructions
  # args[0] is the token if we're sending a password-reset email
  def send_devise_notification(notification, *args)
    PasswordResetEmailJob.perform_async(self.id, args[0]) if notification == :reset_password_instructions
  end

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end
end
