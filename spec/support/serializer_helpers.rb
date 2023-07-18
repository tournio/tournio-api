# frozen_string_literal: true

module SerializerHelpers
  def json_hash
    JSON.parse!(subject).with_indifferent_access
  end
end
