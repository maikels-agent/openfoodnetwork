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

  describe "units" do
    let(:variant) do
      create(:variant, enterprise:, variant_unit:, variant_unit_scale:, unit_value:)
    end

    context "in grams" do
      let(:variant_unit) { "weight" }
      let(:variant_unit_scale) { 1 }
      let(:unit_value) { 500 }

      it "preserves the unit scale" do
        expect(imported_variant.variant_unit).to eq "weight"
        expect(imported_variant.variant_unit_scale).to eq 1
        expect(imported_variant.unit_value).to eq 500
      end
    end

    context "in kilograms" do
      let(:variant_unit) { "weight" }
      let(:variant_unit_scale) { 1_000 }
      let(:unit_value) { 1_500 }

      it "preserves the unit scale" do
        expect(imported_variant.variant_unit).to eq "weight"
        expect(imported_variant.variant_unit_scale).to eq 1_000
        expect(imported_variant.unit_value).to eq 1_500
      end
    end

    context "in millilitres" do
      let(:variant_unit) { "volume" }
      let(:variant_unit_scale) { 0.001 }
      let(:unit_value) { 0.33 }

      it "preserves the unit scale" do
        expect(imported_variant.variant_unit).to eq "volume"
        expect(imported_variant.variant_unit_scale).to eq 0.001
        expect(imported_variant.unit_value).to eq 0.33
      end
    end

    context "in litres" do
      let(:variant_unit) { "volume" }
      let(:variant_unit_scale) { 1 }
      let(:unit_value) { 2 }

      it "preserves the unit scale" do
        expect(imported_variant.variant_unit).to eq "volume"
        expect(imported_variant.variant_unit_scale).to eq 1
        expect(imported_variant.unit_value).to eq 2
      end
    end
  end
end
