# frozen_string_literal: true

class TemplateMailerJob < MailerJob
  def sendgrid_template_id
    raise NotImplementedError
  end

  def personalization_data
    raise NotImplementedError
  end

  def subject
    ''
  end

  # Child classes should call this as the last step in their perform() method,
  # after setting up template data, etc.

  def pre_send
    super
    personalization.add_dynamic_template_data(personalization_data)
    mail.template_id = sendgrid_template_id
  end
end
