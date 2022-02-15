# frozen_string_literal: true

class AdditionalQuestionBlueprint < Blueprinter::Base
  # fields :name, :label, :html_element_type, :html_element_config, :helper_text, :helper_url, :validation_rules
  identifier :id

  fields :label, :order

  # These ones require no transformation, just a rename
  field :html_element_type, name: :elementType
  field :html_element_config, name: :elementConfig

  # requires some transformation...
  field :validation do |aq, _|
    aq.validation_rules
  end
  field :helper do |aq, _|
    {
      url: aq.helper_url,
      text: aq.helper_text,
    }
  end
end
