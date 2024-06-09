# frozen_string_literal: true

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
class AdditionalQuestionSerializer < JsonSerializer
  attributes :identifier,
    :order,
    :name,
    :label

  # Rename these attributes
  attribute :element_config do |aq|
    aq.html_element_config
  end
  attribute :element_type do |aq|
    aq.html_element_type
  end
  attribute :validation do |aq|
    aq.validation_rules
  end

  attribute :helper do |aq|
    {
      url: aq.helper_url,
      text: aq.helper_text,
    }
  end
end
