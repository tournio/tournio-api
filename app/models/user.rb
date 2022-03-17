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
