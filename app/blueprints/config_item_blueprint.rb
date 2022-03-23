class ConfigItemBlueprint < Blueprinter::Base
  fields :id, :key, :value

  field :value_shortened do |c, _|
    c.value.truncate(20)
  end

  field :label do |c, _|
    c.key.humanize(keep_id_suffix: true)
  end
end
