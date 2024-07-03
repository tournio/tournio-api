# frozen_string_literal: true

# == Schema Information
#
# Table name: tournaments
#
#  id                :bigint           not null, primary key
#  aasm_state        :string           not null
#  abbreviation      :string
#  details           :jsonb
#  end_date          :date
#  entry_deadline    :datetime
#  identifier        :string           not null
#  location          :string
#  name              :string           not null
#  start_date        :date
#  timezone          :string           default("America/New_York")
#  year              :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  tournament_org_id :bigint
#
# Indexes
#
#  index_tournaments_on_aasm_state         (aasm_state)
#  index_tournaments_on_identifier         (identifier)
#  index_tournaments_on_tournament_org_id  (tournament_org_id)
#
class TournamentSerializer < JsonSerializer
  attributes :identifier,
    :name,
    :year,
    :abbreviation,
    :start_date,
    :end_date,
    :location,
    :timezone,
    :team_size

  many :additional_questions, resource: AdditionalQuestionSerializer
  many :events, resource: EventSerializer

  # Seems silly to use a block for this, but oh well. Implementation via DSL would wind up
  # doing the same thing, I suppose.
  attribute :state do |t|
    t.aasm_state
  end

  attribute :image_url do |t|
    if params[:host].present? && t.logo_image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(t.logo_image, params)
    end
  end

  attribute :entry_deadline do |t|
    t.entry_deadline&.strftime('%FT%R%:z') || nil
  end

  attribute :config do |t|
    %i(accept_payments bowler_form_fields display_capacity email_in_dev enable_free_entries enable_unpaid_signups publicly_listed team_size tournament_type website).each_with_object({}) do |key, hash|
      hash[key] = t.config[key]
    end
  end

  attribute :starting_date do |t|
    t.start_date.strftime '%B %e, %Y'
  end
end
