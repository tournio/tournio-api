# frozen_string_literal: true

#  category        :string           not null
#  configuration   :jsonb
#  determination   :string
#  enabled         :boolean          default(TRUE)
#  identifier      :string           not null
#  name            :string           not null
#  refinement      :string
#  user_selectable :boolean          default(TRUE), not null
#  value           :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  parent_id       :bigint
#
class PurchasableItemSerializer < JsonSerializer
  attributes :identifier,
    :name,
    :category,
    :determination,
    :refinement,
    :configuration,
    :enabled,
    :user_selectable,
    :value

  many :children, resource: PurchasableItemSerializer
end
