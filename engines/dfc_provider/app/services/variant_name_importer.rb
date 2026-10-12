# frozen_string_literal: true

# OFN exports the product name, variant name and unit as one DFC name.
# We remove the parts which are stored separately to avoid duplication,
# reversing VariantUnits::VariantAndLineItemNaming#product_and_full_name.
#
# For example, a variant of the product "Apples" with the unit "1kg":
#
# - "Apples - 1kg" has no variant name.
# - "Apples - Granny Smith (1kg)" has the variant name "Granny Smith".
class VariantNameImporter
  def self.display_name(name, variant)
    product_name = variant.product.name
    name = name.to_s.delete_prefix("#{product_name} - ") if product_name.present?
    unit = VariantUnits::OptionValueNamer.new(variant).name

    return if name.blank? || name == product_name || name == unit

    name.delete_suffix(" (#{unit})")
  end
end
