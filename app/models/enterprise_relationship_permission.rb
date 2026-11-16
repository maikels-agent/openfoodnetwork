# frozen_string_literal: true

class EnterpriseRelationshipPermission < ApplicationRecord
  ALL = %w[
    add_to_order_cycle
    manage_products
    edit_profile
    create_variant_overrides
    create_linked_variants
  ].freeze

  belongs_to :enterprise_relationship
  default_scope { order('name') }
  before_destroy :destroy_related_exchanges

  def destroy_related_exchanges
    return if name != "add_to_order_cycle"

    Exchange
      .where(sender: enterprise_relationship.parent,
             receiver: enterprise_relationship.child, incoming: true).destroy_all
  end
end
