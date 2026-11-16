# frozen_string_literal: true

module Admin
  module OrdersHelper
    AdjustmentData = Struct.new(:label, :amount)

    # Order cycles to choose from for each shop:
    #
    #   [[shop_id, [["Order cycle name (open)", order_cycle_id], ...]], ...]
    def order_cycle_options_by_distributor(shops, order_cycles)
      shops.map do |shop|
        options = order_cycles.select { |order_cycle| order_cycle.distributors.include?(shop) }
          .map { |order_cycle| [order_cycle_name_and_status(order_cycle), order_cycle.id] }

        [shop.id, options]
      end
    end

    # Shops without order cycles can't be selected.
    def distributor_options(shops, order_cycle_options)
      order_cycle_options = order_cycle_options.to_h

      shops.map do |shop|
        [shop.name, shop.id, { disabled: order_cycle_options[shop.id].blank? }]
      end
    end

    def order_cycle_name_and_status(order_cycle)
      status = t(order_cycle_status_class(order_cycle), scope: "admin.order_cycles.status")

      "#{order_cycle.name} (#{status})"
    end

    # Adjustments to display under "Order adjustments".
    #
    # We exclude shipping method adjustments because they are displayed in a
    # separate table together with the order line items.
    def order_adjustments_for_display(order)
      order.adjustments +
        voucher_included_tax_representations(order) +
        additional_tax_total_representation(order) +
        order.all_adjustments.payment_fee.eligible
    end

    def additional_tax_total_representation(order)
      adjustment = Spree::Adjustment.additional.tax.where(
        order_id: order.id, adjustable_type: 'Spree::Adjustment'
      ).sum(:amount)

      return [] unless adjustment != 0

      [
        AdjustmentData.new(
          I18n.t("admin.orders.edit.tax_on_fees"),
          adjustment
        )
      ]
    end

    def voucher_included_tax_representations(order)
      return [] unless VoucherAdjustmentsService.new(order).voucher_included_tax.negative?

      adjustment = order.voucher_adjustments.first

      [
        AdjustmentData.new(
          I18n.t("admin.orders.edit.voucher_tax_included_in_price",
                 label: adjustment.label),
          adjustment.included_tax
        )
      ]
    end
  end
end
