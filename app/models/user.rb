class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Allowlist

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         # :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

  enum role: %i[unpermitted director superuser]

  before_create :generate_identifier

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end
end