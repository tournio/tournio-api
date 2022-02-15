# == Schema Information
#
# Table name: additional_question_responses
#
#  id                     :bigint           not null, primary key
#  response               :string           default("")
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  bowler_id              :bigint
#  extended_form_field_id :bigint
#
# Indexes
#
#  index_additional_question_responses_on_bowler_id               (bowler_id)
#  index_additional_question_responses_on_extended_form_field_id  (extended_form_field_id)
#
class AdditionalQuestionResponse < ApplicationRecord
  belongs_to :bowler
  belongs_to :extended_form_field

  accepts_nested_attributes_for :extended_form_field

  delegate :label, :name, to: :extended_form_field
end
