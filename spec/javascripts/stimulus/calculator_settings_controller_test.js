/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import calculator_settings_controller from "../../../app/webpacker/controllers/calculator_settings_controller";

describe("CalculatorSettingsController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("calculator-settings", calculator_settings_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="calculator-settings" data-calculator-settings-original-value="flat">
        <select id="type" data-action="calculator-settings#toggle">
          <option value="flat" selected>Flat</option>
          <option value="weight">Weight</option>
        </select>
        <div id="settings" data-calculator-settings-target="settings">
          <input id="amount" />
        </div>
      </div>`;
  });

  const select = (value) => {
    const type = document.getElementById("type");
    type.value = value;
    type.dispatchEvent(new Event("change"));
  };

  it("hides and disables settings of another calculator type", () => {
    select("weight");

    expect(document.getElementById("settings").hidden).toBe(true);
    expect(document.getElementById("amount").disabled).toBe(true);
  });

  it("shows settings again when selecting the original type", () => {
    select("weight");
    select("flat");

    expect(document.getElementById("settings").hidden).toBe(false);
    expect(document.getElementById("amount").disabled).toBe(false);
  });
});
