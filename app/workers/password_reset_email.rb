# frozen_string_literal: true

class PasswordResetEmail < TemplateMailerWorker
  attr_accessor :recipient, :token

  def perform(user_id, token)
    user = User.find(user_id)
    unless user.present?
      logger.warn "Trying to send a password-reset email to a user that doesn't exist."
      return
    end

    self.token = token
    self.recipient = user.email

    send
  end

  def to_address
    Rails.env.production? ? recipient : FROM_ADDRESS
  end

  def personalization_data
    {
      reset_password_url: reset_url,
    }
  end

  def sendgrid_template_id
    'd-6c19955450244cc899cb4c2dd23b7447'
  end

  def subject
    'Reset your password'
  end

  def reply_to
    FROM
  end

  def reset_url
    if Rails.env.production?
      "https://www.igbo-reg.com/director/password-reset?token=#{token}"
    else
      "http://localhost:3000/director/password-reset?token=#{token}"
    end
  end
end
