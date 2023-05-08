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
require 'rails_helper'

RSpec.describe SendGridEvent, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
