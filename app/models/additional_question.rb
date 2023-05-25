# == Schema Information
#
# Table name: additional_questions
#
#  id                     :bigint           not null, primary key
#  identifier             :string
#  order                  :integer
#  validation_rules       :jsonb
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  extended_form_field_id :bigint
#  tournament_id          :bigint
#
# Indexes
#
#  index_additional_questions_on_extended_form_field_id  (extended_form_field_id)
#  index_additional_questions_on_tournament_id           (tournament_id)
#
class AdditionalQuestion < ApplicationRecord
  belongs_to :tournament
  belongs_to :extended_form_field

  before_create :generate_identifier

  delegate :helper_text, :helper_url, :html_element_config, :html_element_type, :label, :name, to: :extended_form_field

  private

  def generate_identifier
    self.identifier = SecureRandom.uuid
  end
end
