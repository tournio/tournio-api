class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Allowlist

  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

  enum role: %i[unpermitted director superuser]

  has_and_belongs_to_many :tournaments

  before_create :generate_identifier

  def jwt_payload
    {
      'role' => role.to_s,
      'tournaments' => tournaments.pluck(:identifier)
    }
  end

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end
end