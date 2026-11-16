/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import resend_confirmation_controller from "../../../app/webpacker/controllers/resend_confirmation_controller";

describe("ResendConfirmationController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("resend-confirmation", resend_confirmation_controller);

    global.I18n = { t: (key) => key.split(".").pop() };
  });

  afterAll(() => {
    delete global.I18n;
    delete global.fetch;
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <a id="link" href="#" data-controller="resend-confirmation"
        data-action="resend-confirmation#resend:prevent"
        data-resend-confirmation-email-value="user@example.net">resend</a>`;
  });

  // Let the promises of the request settle.
  const settle = () => new Promise((resolve) => setTimeout(resolve));

  it("requests a new confirmation email once", async () => {
    global.fetch = jest.fn(() => Promise.resolve({ ok: true }));
    const link = document.getElementById("link");

    link.click();
    expect(link.textContent).toBe("sending");

    await settle();

    expect(global.fetch).toHaveBeenCalledWith(
      "/user/spree_user/confirmation",
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ spree_user: { email: "user@example.net" } }),
      }),
    );
    expect(link.textContent).toBe("done");
    expect(link.classList).toContain("action--disabled");

    link.click();
    await settle();

    expect(global.fetch).toHaveBeenCalledTimes(1);
    expect(link.textContent).toBe("done");
  });

  it("shows a failure and allows trying again", async () => {
    global.fetch = jest.fn(() => Promise.resolve({ ok: false }));
    const link = document.getElementById("link");

    link.click();
    await settle();

    expect(link.textContent).toBe("failed");

    global.fetch = jest.fn(() => Promise.resolve({ ok: true }));
    link.click();
    await settle();

    expect(link.textContent).toBe("done");
  });
});
