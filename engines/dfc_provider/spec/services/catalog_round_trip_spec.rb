# frozen_string_literal: true

require_relative "../spec_helper"

# Exporting a catalog and importing it again should preserve product data.
#
# Our unit specs build DFC objects in Ruby and therefore don't notice when
# our serialised JSON-LD is missing a link between those objects. Here we
# serialise like the CatalogItems endpoint does and parse the result again.
RSpec.describe "DFC catalog round trip" do
  subject(:imported_variant) do
    SuppliedProductImporter.import_variant(imported_product, enterprise)
  end

  let(:enterprise) { create(:supplier_enterprise) }
  let(:imported_product) { DfcCatalog.from_json(catalog_json).products.first }
  # Serialise like DfcProvider::CatalogItemsController#index does.
  let(:catalog_json) do
    items = [CatalogItemBuilder.catalog_item(variant)]
    DfcIo.export(
      *items,
      *items.map(&:product),
      *items.map(&:product).flat_map(&:isVariantOf),
      *items.flat_map(&:offers),
    )
  end

  describe "stock controlled variant" do
    let(:variant) do
      create(:variant, enterprise:, price: 14.99, on_demand: false, on_hand: 7)
    end

    it "preserves the price" do
      expect(imported_variant.price).to eq 14.99
    end

    it "preserves the stock level" do
      imported_variant.save!

      expect(imported_variant.on_demand).to eq false
      expect(imported_variant.on_hand).to eq 7
    end
  end

  describe "on-demand variant" do
    let(:variant) do
      create(:variant, enterprise:, price: 3.50, on_demand: true)
    end

    it "preserves the price" do
      expect(imported_variant.price).to eq 3.50
    end
  end

  describe "names" do
    let(:product) { create(:product, name: "Apples", enterprise_id: enterprise.id) }
    let(:variant) do
      create(:variant, product:, enterprise:, display_name:, unit_value: 500)
    end

    context "without variant name" do
      let(:display_name) { nil }

      it "preserves the product name and leaves the variant name blank" do
        expect(imported_variant.product.name).to eq "Apples"
        expect(imported_variant.display_name).to eq nil

        imported_variant.save! # assigns unit presentation
        expect(imported_variant.product_and_full_name).to eq "Apples - 500g"
      end
    end

    context "with variant name" do
      let(:display_name) { "Granny Smith" }

      it "preserves the variant name" do
        expect(imported_variant.product.name).to eq "Apples"
        expect(imported_variant.display_name).to eq "Granny Smith"

        imported_variant.save! # assigns unit presentation
        expect(imported_variant.product_and_full_name)
          .to eq "Apples - Granny Smith (500g)"
      end
    end

    context "imported as new product" do
      subject(:imported_variant) do
        SuppliedProductImporter.import_variant(
          imported_product, create(:supplier_enterprise)
        )
      end
      let(:display_name) { "Granny Smith" }

      it "preserves product name and variant name" do
        expect(imported_variant.product).not_to eq product
        expect(imported_variant.product.name).to eq "Apples"
        expect(imported_variant.display_name).to eq "Granny Smith"
      end
    end

    context "with variant name containing the unit" do
      let(:display_name) { "Granny Smith 500g" }

      it "preserves the variant name" do
        expect(imported_variant.display_name).to eq "Granny Smith 500g"
      end
    end
  end
end
