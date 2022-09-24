class ConfigItemBlueprint < Blueprinter::Base
  fields :id, :key

  field :value do |c, _|
    if %w(email_in_dev display_capacity).include?(c.key)
      %w(true t T).include?(c.value)
    else
      c.value
    end
  end

  field :value_shortened do |c, _|
    c.value.truncate(20)
  end

  field :label do |c, _|
    c.key.humanize(keep_id_suffix: true)
  end
end
