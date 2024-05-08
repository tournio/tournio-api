# frozen_string_literal: true

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
