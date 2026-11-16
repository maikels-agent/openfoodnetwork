import { Controller } from "stimulus";

// Prevents submitting a form more than once, for example when taking a payment.
//
//   %form{ data: { controller: "submit-once", action: "submit@window->submit-once#guard" } }
//
// The submit event is observed on the window to see only submissions which
// are really happening. Other controllers may cancel a submission and stop
// its propagation to do some work first and then submit again.
export default class extends Controller {
  guard(event) {
    if (event.target !== this.element || event.defaultPrevented) return;

    if (this.submitted) {
      event.preventDefault();
      return;
    }

    this.submitted = true;
    this.element.classList.add("submitted");
  }
}
