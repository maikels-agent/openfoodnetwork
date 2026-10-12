# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe VariantNameImporter do
  let(:product) { build(:product, name: "Apples") }
  let(:variant) {
    build(:variant, product:, variant_unit: "weight", variant_unit_scale: 1000, unit_value: 1000)
  }

  def display_name(name)
    described_class.display_name(name, variant)
  end

  it "removes product name and unit" do
    expect(display_name("Apples - 1kg")).to eq nil
    expect(display_name("Apples")).to eq nil
    expect(display_name("Apples - Granny Smith (1kg)")).to eq "Granny Smith"
    expect(display_name("Apples - Granny Smith 1kg")).to eq "Granny Smith 1kg"
  end

  it "keeps other names" do
    expect(display_name("Pears - Conference")).to eq "Pears - Conference"
    expect(display_name("Retail pack, 300g")).to eq "Retail pack, 300g"
  end

  it "ignores a blank name" do
    expect(display_name(nil)).to eq nil
  end
end
