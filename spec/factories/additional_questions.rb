# == Schema Information
#
# Table name: additional_questions
#
#  id                     :bigint           not null, primary key
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
FactoryBot.define do
  factory :additional_question do
    
  end
end
