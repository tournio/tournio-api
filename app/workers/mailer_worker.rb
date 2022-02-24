# frozen_string_literal: true

class MailerWorker
  include Sidekiq::Worker
  include SendGrid

  sidekiq_options retry: false, queue: 'mailers'

  sidekiq_retries_exhausted do |msg, _ex|
    logger.warn "I have failed to send a message. #{msg}"
  end

  FROM_ADDRESS = 'info@igbo-reg.com'
  FROM = "Tournament Registration <#{FROM_ADDRESS}>"

  ENV_API_KEY = 'SENDGRID_API_KEY'

  attr_reader :personalization, :mail

  def initialize
    @personalization = Personalization.new

    @mail = Mail.new
    @mail.from = Email.new(email: FROM)
  end

  def reply_to
    FROM
  end

  #
  # These are the methods that child classes must implement, in addition to perform(...)
  #
  # Their perform() method must call send() as the last thing they do.
  #
  def to_address
    FROM
  end

  def subject
    raise NotImplementedError
  end

  # If a child class wants to add anything to the personalization or mail objects
  # before we send off the message, they can override this method.
  def pre_send
    personalization.subject = subject
    mail.reply_to = Email.new(email: reply_to)
  end

  # Child classes should call this as the last step in their perform() method,
  # after setting up template data, etc.

  def send
    pre_send
    send_message
  end

  def send_message
    personalization.add_to(Email.new(email: to_address))
    mail.add_personalization(personalization)

    sg = SendGrid::API.new(api_key: ENV[ENV_API_KEY])
    begin
      response = sg.client.mail._("send").post(request_body: mail.to_json)
    rescue Exception => e
      logger.warn(e.message)
      puts e
    end
  end
end
