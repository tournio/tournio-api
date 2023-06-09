class ConfigItemBlueprint < Blueprinter::Base
  fields :id, :key

  field :value do |c, _|
    if %w(email_in_dev display_capacity skip_stripe publicly_listed).include?(c.key)
      self.boolean_value(c.value)
    else
      c.value
    end
  end

  field :value_shortened do |c, _|
    if %w(email_in_dev display_capacity skip_stripe publicly_listed).include?(c.key)
      self.boolean_value(c.value)
    else
      c.value.truncate(20)
    end
  end

  field :label do |c, _|
    c.key.humanize(keep_id_suffix: true)
  end

  def self.boolean_value(value)
    %w(true t T).include?(value)
  end
end
