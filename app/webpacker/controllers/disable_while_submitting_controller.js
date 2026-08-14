import { Controller } from "stimulus";

// Ignore repeated clicks on a data-turbo-method link while its request is in
// flight, like the old mrujs data-disable-with did.
//
// Turbo disables the submit button of a form during submission but the hidden
// form it builds for a data-turbo-method link has no submit button, so a double
// click sends the request twice.
export default class extends Controller {
  connect() {
    this.enable = this.enable.bind(this);
  }

  disconnect() {
    document.removeEventListener("turbo:submit-end", this.enable);
  }

  click(event) {
    if (this.element.getAttribute("aria-disabled") === "true") {
      event.preventDefault();
      return;
    }

    this.element.setAttribute("aria-disabled", "true");
    document.addEventListener("turbo:submit-end", this.enable, { once: true });
  }

  enable() {
    this.element.removeAttribute("aria-disabled");
  }
}
