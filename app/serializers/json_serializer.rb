# frozen_string_literal: true

class JsonSerializer
  include Alba::Resource

  transform_keys :lower_camel
end
