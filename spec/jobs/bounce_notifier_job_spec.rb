# frozen_string_literal: true
# frozen_string_literal: true

require "rails_helper"

RSpec.describe BounceNotifierJob, type: :job do
  describe '#perform' do
    subject { described_class.new.perform(sg_event_id) }

    let(:sg_event_id) { '123' }
  end
end
