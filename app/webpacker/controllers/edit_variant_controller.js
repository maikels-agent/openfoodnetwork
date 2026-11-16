import { Controller } from "stimulus";
import OptionValueNamer from "js/services/option_value_namer";
import UnitPrices from "js/services/unit_prices";

// Dynamically update related variant fields
//
// The fields are found by their id which starts with the name of the form's
// model. That's "variant" by default. The new product form contains the same
// fields for the product's first variant:
//
//   %fieldset{ data: { controller: "edit-variant", "edit-variant-prefix-value": "product" } }
//
// Optional targets are only shown for certain units:
//
//   %div{ data: { "edit-variant-target": "itemsOnly" } }
//   %div{ data: { "edit-variant-target": "unlessItems" } }
//
// TODO refactor so we can extract what's common with Bulk product page
export default class EditVariantController extends Controller {
  static targets = ["onHand", "itemsOnly", "unlessItems"];
  static values = { prefix: { type: String, default: "variant" } };

  connect() {
    this.unitPrices = new UnitPrices();
    // idea: create a helper that includes a nice getter/setter for Rails model attr values, just pass it the attribute name.
    // It could automatically find (and cache a ref to) each dom element and get/set the values.
    this.variantUnit = this.#field("variant_unit");
    this.variantUnitScale = this.#field("variant_unit_scale");
    this.variantUnitName = this.#field("variant_unit_name");
    this.variantUnitWithScale = this.#field("variant_unit_with_scale");
    this.variantPrice = this.#field("price");

    // on variant_unit_with_scale changed; update variant_unit and variant_unit_scale
    this.variantUnitWithScale.addEventListener("change", this.#updateUnitAndScale.bind(this), {
      passive: true,
    });

    this.unitValue = this.#field("unit_value");
    this.unitDescription = this.#field("unit_description");
    this.unitValueWithDescription = this.#field("unit_value_with_description");
    this.displayAs = this.#field("display_as");
    this.unitToDisplay = this.#field("unit_to_display");
    this.unitPrice = this.#field("unit_price");
    this.weight = this.#field("weight");

    // on unit changed; update display_as:placeholder and unit_to_display
    [this.variantUnit, this.variantUnitScale, this.variantUnitName].forEach((element) => {
      element.addEventListener("change", this.#unitChanged.bind(this), { passive: true });
    });
    this.variantUnitName.addEventListener("input", this.#unitChanged.bind(this), { passive: true });

    // on unit_value_with_description changed; update unit_value and unit_description
    // on unit_value and/or unit_description changed; update display_as:placeholder and unit_to_display
    this.unitValueWithDescription.addEventListener("input", this.#unitChanged.bind(this), {
      passive: true,
    });

    // on display_as changed; update unit_to_display
    // TODO: optimise to avoid unnecessary OptionValueNamer calc
    this.displayAs.addEventListener("input", this.#updateUnitDisplay.bind(this), { passive: true });

    // update Unit price when variant_unit_with_scale or price changes
    [this.variantUnitWithScale, this.variantPrice].forEach((element) => {
      element.addEventListener("change", this.#processUnitPrice.bind(this), { passive: true });
    });
    this.variantPrice.addEventListener("input", this.#processUnitPrice.bind(this), {
      passive: true,
    });
    this.variantUnitName.addEventListener("input", this.#processUnitPrice.bind(this), {
      passive: true,
    });
    this.unitValueWithDescription.addEventListener("input", this.#processUnitPrice.bind(this), {
      passive: true,
    });

    // on variantUnit change we need to check if weight needs to be toggled
    this.variantUnit.addEventListener("change", this.#toggleWeight.bind(this), { passive: true });

    // on variantUnit change; show only the fields relevant to that unit
    this.variantUnit.addEventListener("change", this.#toggleUnitFields.bind(this), {
      passive: true,
    });
    this.#toggleUnitFields();

    // make sure the unit is correct when page is reload after an error
    this.#updateUnitDisplay();
    // update unit price on page load
    this.#processUnitPrice();

    if (this.variantUnit.value === "weight") {
      return this.#hideWeight();
    }
  }

  disconnect() {
    // Make sure to clean up anything that happened outside
    // TODO remove all added event
    this.variantUnit.removeEventListener("change", this.#toggleWeight.bind(this), {
      passive: true,
    });
  }

  toggleOnHand(event) {
    if (event.target.checked === true) {
      this.onHandTarget.dataStock = this.onHandTarget.value;
      this.onHandTarget.value = I18n.t("admin.products.variants.infinity");
      this.onHandTarget.disabled = "disabled";
    } else {
      this.onHandTarget.removeAttribute("disabled");
      this.onHandTarget.value = this.onHandTarget.dataStock;
    }
  }

  // private

  // Extract variant_unit and variant_unit_scale from dropdown variant_unit_with_scale,
  // and update hidden product fields
  #unitChanged(event) {
    //Hmm in hindsight the logic in product_controller should be inn this controller already. then we can do everything in one event, and store the generated name in an instance variable.
    this.#extractUnitValues();
    this.#updateUnitDisplay();
  }

  // Extract unit_value and unit_description
  #extractUnitValues() {
    // Extract a number (optional) and text value, separated by a space.
    const match = this.unitValueWithDescription.value.match(/^([\d\.\,]+(?= |$)|)( |)(.*)$/);
    if (match) {
      let unit_value = parseFloat(match[1].replace(",", "."));
      if (isNaN(unit_value)) {
        unit_value = ""; // A missing value is not zero.
      } else {
        unit_value *= this.variantUnitScale.value ? this.variantUnitScale.value : 1; // Normalise to default scale
      }

      this.unitValue.value = unit_value;
      this.unitDescription.value = match[3];
    }
  }

  // Update display_as placeholder and unit_to_display
  #updateUnitDisplay() {
    const unitDisplay = new OptionValueNamer(this.#variant()).name();
    this.displayAs.placeholder = unitDisplay;
    if (this.unitToDisplay) {
      this.unitToDisplay.textContent = this.displayAs.value || unitDisplay;
    }
  }

  // A representation of the variant model to satisfy OptionValueNamer.
  #variant() {
    return {
      unit_value: parseFloat(this.unitValue.value),
      unit_description: this.unitDescription.value,
      variant_unit: this.variantUnit.value,
      variant_unit_scale: parseFloat(this.variantUnitScale.value),
      variant_unit_name: this.variantUnitName.value,
    };
  }

  // Extract variant_unit and variant_unit_scale from dropdown variant_unit_with_scale,
  // and update hidden product fields
  #updateUnitAndScale(event) {
    const variant_unit_with_scale = this.variantUnitWithScale.value;
    const match = variant_unit_with_scale.match(/^([^_]+)_([\d\.]+)$/); // eg "weight_1000"

    if (match) {
      this.variantUnit.value = match[1];
      this.variantUnitScale.value = parseFloat(match[2]);
    } else {
      // "items"
      this.variantUnit.value = variant_unit_with_scale;
      this.variantUnitScale.value = "";
    }
    this.variantUnit.dispatchEvent(new Event("change"));
    this.variantUnitScale.dispatchEvent(new Event("change"));
  }

  #processUnitPrice() {
    const unit_type = this.variantUnit.value;

    // TODO double check this
    let unit_value = 1;
    if (unit_type != "items") {
      unit_value = this.unitValue.value;
    }

    const unit_price = this.unitPrices.displayableUnitPrice(
      this.variantPrice.value,
      parseFloat(this.variantUnitScale.value),
      unit_type,
      unit_value,
      this.variantUnitName.value,
    );

    this.unitPrice.value = unit_price;
  }

  #field(name) {
    return this.element.querySelector(`[id="${this.prefixValue}_${name}"]`);
  }

  #toggleUnitFields() {
    const items = this.variantUnit.value === "items";

    this.itemsOnlyTargets.forEach((element) => this.#toggleFields(element, items));
    this.unlessItemsTargets.forEach((element) => this.#toggleFields(element, !items));
  }

  // Hidden fields are disabled so that they are not submitted.
  #toggleFields(element, show) {
    element.style.display = show ? "" : "none";
    element.querySelectorAll("input, select").forEach((field) => {
      field.disabled = !show;
    });
  }

  #hideWeight() {
    if (!this.weight) return;

    this.weight.parentElement.style.display = "none";
  }

  #toggleWeight() {
    if (this.variantUnit.value === "weight") {
      return this.#hideWeight();
    }
    if (!this.weight) return;

    // Show weight
    this.weight.parentElement.style.display = "block";
    // Clearing weight value to remove calculated weight for a variant with unit set to "weight"
    // See Spree::Variant hook update_weight_from_unit_value
    this.weight.value = "";
  }
}
