# frozen_string_literal: true

class PasswordResetEmail < TemplateMailerWorker
  attr_accessor :recipient

  def perform(user_id)
    user = User.find(user_id)
    unless user.present?
      logger.warn "Trying to send a password-reset email to a user that doesn't exist."
      return
    end
    unless user.reset_password_token.present?
      logger.warn "There is no reset password token on the requested user."
      return
    end

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
      "https://www.igbo-reg.com/#{bowler.team.identifier}"
    else
      "http://localhost:3000/#{bowler.team.identifier}"
    end
  end
end
