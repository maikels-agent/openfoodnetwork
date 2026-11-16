# frozen_string_literal: true

module Admin
  module EnterpriseRelationshipsHelper
    PERMISSION_TRANSLATION_KEYS = {
      "create_variant_overrides" => "add_products_to_inventory",
    }.freeze

    def enterprise_relationship_permission_name(permission)
      key = PERMISSION_TRANSLATION_KEYS.fetch(permission, permission)

      t(key, scope: "js.services")
    end
  end
end
