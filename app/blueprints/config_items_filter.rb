class ConfigItemsFilter < Blueprinter::Transformer
  def transform(result_hash, primary_obj, options = nil)
    index = result_hash[:config_items].index { |ci| ci[:key] == 'entry_deadline' }
    value = result_hash[:config_items][index][:value]
    result_hash[:config_items][index][:value] = DateTime.parse(value).strftime('%FT%T')
  end
end
