class ConfigItemBlueprint < Blueprinter::Base
  fields :id, :key, :label

  field :value do |c, _|
    if %w(email_in_dev display_capacity skip_stripe publicly_listed accept_payments enable_unpaid_signups enable_free_entries).include?(c.key)
      self.boolean_value(c.value)
    elsif c.key == 'bowler_form_fields'
      c.value.split(' ')
    else
      c.value
    end
  end

  field :value_shortened do |c, _|
    if %w(email_in_dev display_capacity skip_stripe publicly_listed accept_payments enable_unpaid_signups enable_free_entries).include?(c.key)
      self.boolean_value(c.value)
    else
      c.value.truncate(20)
    end
  end

  def self.boolean_value(value)
    %w(true t T).include?(value)
  end
end
