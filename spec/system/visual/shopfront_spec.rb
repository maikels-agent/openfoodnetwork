# frozen_string_literal: true

require "system_helper"

RSpec.describe "Shopfront", :visual do
  let(:shop) {
    create(:distributor_enterprise, name: "Green Valley Hub", with_payment_and_shipping: true)
  }
  let(:farm) { create(:supplier_enterprise, name: "Hilltop Farm") }

  before do
    products = [
      ["Apples", 3.5], ["Carrots", 2], ["Free range eggs", 7.25],
    ].map do |name, price|
      description = "Fresh #{name.downcase}"
      create(:product, name:, price:, description:, enterprise_id: farm.id)
    end

    create(
      :simple_order_cycle,
      name: "Weekly box",
      distributors: [shop], coordinator: shop,
      variants: products.map { |product| product.variants.first },
      orders_close_at: 3.days.from_now
    )
  end

  it "lists the products of the current order cycle" do
    visit enterprise_shop_path(shop)

    expect(page).to have_content "Free range eggs"
    expect_visual_match "shopfront/products"
  end
end
