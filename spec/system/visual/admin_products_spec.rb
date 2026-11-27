# frozen_string_literal: true

require "system_helper"

RSpec.describe "Admin products", :visual do
  let(:farm) { create(:supplier_enterprise, name: "Hilltop Farm") }
  let(:user) { create(:user, email: "farmer@example.org", enterprises: [farm]) }

  before do
    [["Apples", 3.5, 10], ["Carrots", 2, 0],
     ["Free range eggs", 7.25, 25]].each do |name, price, stock|
      create(:product, name:, price:, on_hand: stock, enterprise_id: farm.id)
    end

    login_as user
  end

  it "shows the bulk edit table" do
    visit admin_products_path

    expect(page).to have_field "Name", with: "Free range eggs"
    expect_visual_match "admin/products"
  end
end
