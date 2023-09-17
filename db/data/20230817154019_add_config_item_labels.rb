# frozen_string_literal: true

class AddConfigItemLabels < ActiveRecord::Migration[7.0]
  def up
    labels = {
      accept_payments: "Accept Payments",
      display_capacity: "Display Capacity",
      email_in_dev: "[dev] Send Emails",
      publicly_listed: "Publicly Listed",
      skip_stripe: "Skip Stripe",
      team_size: "Tournament Team Size",
      website: "Website URL",
    }
    labels.each_pair do |key, label|
      ConfigItem.where(key: key).update_all(label: label)
    end
  end

  def down
  end
end
