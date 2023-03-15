class TournamentConfig
  def initialize(tournamenmt_config_items)
    self.config_items = tournamenmt_config_items
  end

  def [](key)
    str = str_key(key)

    value = config_items.find_by_key(str)&.value
    integer_value = Integer(value, exception: false)
    if value == 'true' || value == 't'
      value = true
    elsif value == 'false'|| value == 'f'
      value = false
    elsif integer_value.present?
      value = integer_value
    end
    value
  end

  def []=(key, value)
    str = str_key(key)
    config_item = config_items.find_by_key(str)
    unless config_item.nil?
      config_item.update(value: value.to_s)
      self
    end
  end

  private

  attr_accessor :config_items

  def str_key(key)
    key.class == 'String' ? key : key.to_s
  end
end
