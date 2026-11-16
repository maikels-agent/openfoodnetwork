# frozen_string_literal: true

module EnterpriseFeesHelper
  # Still used by the AngularJS customers page.
  def angular_name(method)
    "sets_enterprise_fee_set[collection_attributes][{{ $index }}][#{method}]"
  end

  def angular_id(method)
    "sets_enterprise_fee_set_collection_attributes_{{ $index }}_#{method}"
  end

  def enterprise_fee_type_options
    EnterpriseFee::FEE_TYPES.map { |fee_type| [t("#{fee_type}_fee"), fee_type] }
  end

  # The tax category can be inherited from the product. That option is
  # presented as an additional tax category.
  INHERITED_TAX_CATEGORY_ID = -1

  def enterprise_fee_tax_category_options(tax_categories)
    [[t("js.admin.enterprise_fees.inherit_from_product"), INHERITED_TAX_CATEGORY_ID]] +
      tax_categories.map { |tax_category| [tax_category.name, tax_category.id] }
  end

  def enterprise_fee_tax_category_id(enterprise_fee)
    return INHERITED_TAX_CATEGORY_ID if enterprise_fee.inherits_tax_category

    enterprise_fee.tax_category_id
  end
end
