# == Schema Information
#
# Table name: send_grid_events
#
#  email           :string
#  event_timestamp :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  sg_event_id     :string           not null, primary key
#
class SendGridEvent < ApplicationRecord
end
