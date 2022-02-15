class ConfigItemBlueprint < Blueprinter::Base
  fields :id, :key

  field :value do |c, _|
    c.value.truncate(20)
  end

  field :label do |c, _|
    c.key.humanize(keep_id_suffix: true)
  end
end
