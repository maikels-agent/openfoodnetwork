import { Controller } from "stimulus";

// Hides and disables the settings of a calculator when another calculator
// type is selected. The settings of the new calculator are only available
// after saving. Submitting the old settings for a new calculator would fail.
//
//   %tr{ data: { controller: "calculator-settings",
//                "calculator-settings-original-value": "Calculator::FlatRate" } }
//     %select{ data: { action: "calculator-settings#toggle" } }
//     %div{ data: { "calculator-settings-target": "settings" } }
//
export default class extends Controller {
  static targets = ["settings"];
  static values = { original: String };

  toggle(event) {
    const unchanged = event.target.value === this.originalValue;

    this.settingsTargets.forEach((settings) => {
      settings.hidden = !unchanged;
      settings.querySelectorAll("input, select").forEach((field) => {
        field.disabled = !unchanged;
      });
    });
  }
}
