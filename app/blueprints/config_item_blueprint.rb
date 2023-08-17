class ConfigItemBlueprint < Blueprinter::Base
  fields :id, :key, :label

  field :value do |c, _|
    if %w(email_in_dev display_capacity skip_stripe publicly_listed accept_payments automatic_discount_voids).include?(c.key)
      self.boolean_value(c.value)
    else
      c.value
    end
  end

  field :value_shortened do |c, _|
    if %w(email_in_dev display_capacity skip_stripe publicly_listed accept_payments automatic_discount_voids).include?(c.key)
      self.boolean_value(c.value)
    else
      c.value.truncate(20)
    end
  end

  def self.boolean_value(value)
    %w(true t T).include?(value)
  end
end
