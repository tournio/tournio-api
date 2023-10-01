# frozen_string_literal: true

# == Schema Information
#
# Table name: tournament_orgs
#
#  id         :bigint           not null, primary key
#  identifier :string           not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tournament_orgs_on_identifier  (identifier) UNIQUE
#
#

class TournamentOrg < ApplicationRecord
  has_and_belongs_to_many :users
  has_many :tournaments
  has_one :stripe_account

  before_create :generate_identifier

  # This allows us to use the org's identifier instead of numeric ID as its helper parameter
  def to_param
    identifier
  end

  private

  def generate_identifier
    begin
      self.identifier = SecureRandom.alphanumeric(6)
    end while TournamentOrg.exists?(identifier: self.identifier)
  end
end

# Tournament Organization
# - identifier
# - name
#
# has_many:
#   - users (and belongs to many) -- a user can see/admin all the org's tournaments
#   -- a user may be part of multiple orgs
# - tournaments
#   -- opens the door to a tournament gaining flexibility in terms of format (standard, non-traditional, fundraiser, etc)
#
# has_one
# - stripe account (on this instead of on tournament)
#
#
# Changes to StripeAccount:
# - belongs_to changes from Tournament to Organization
#
# Changes to Tournament:
# - belongs_to Organization
# - has_one :stripe_account
#     changes to
#   :stripe_account method delegated to Organization*
# * as a bridge toward completely decoupling Tournament from StripeAccount
#

# Destructive changes to apply afterward:
#  - drop tournaments_users
#  - remove column: stripe_accounts.tournament_id
#  - remove :optional flag on belongs_to association for stripe_account and tournament
