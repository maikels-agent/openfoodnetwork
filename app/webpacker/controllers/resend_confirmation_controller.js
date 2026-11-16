import { Controller } from "stimulus";

// Requests another confirmation email for a user and displays the progress
// within the controlled element.
//
//   %a{ href: "#", data: { controller: "resend-confirmation",
//                         action: "resend-confirmation#resend:prevent",
//                         "resend-confirmation-email-value": user.email } }
//
export default class extends Controller {
  static values = { email: String };

  resend() {
    if (this.sent) return;

    this.#show("sending");

    return fetch("/user/spree_user/confirmation", {
      method: "POST",
      headers: {
        Accept: "application/json, text/plain, */*",
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
      },
      body: JSON.stringify({ spree_user: { email: this.emailValue } }),
    })
      .then((response) => {
        if (!response.ok) throw response;

        this.sent = true;
        this.element.classList.add("action--disabled");
        this.#show("done");
      })
      .catch(() => {
        this.#show("failed");
      });
  }

  // private

  #show(status) {
    this.element.textContent = I18n.t(`js.admin.resend_user_email_confirmation.${status}`);
  }
}
