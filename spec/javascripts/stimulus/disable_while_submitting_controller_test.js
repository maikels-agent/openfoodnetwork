/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import disable_while_submitting_controller from "../../../app/webpacker/controllers/disable_while_submitting_controller";

describe("DisableWhileSubmittingController", () => {
  let link;
  let clicks;

  beforeAll(() => {
    const application = Application.start();
    application.register("disable-while-submitting", disable_while_submitting_controller);

    // Count the clicks that would reach Turbo's click listener on window.
    window.addEventListener("click", (event) => {
      if (!event.defaultPrevented) clicks++;
      event.preventDefault();
    });
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <a id="link" href="#"
         data-controller="disable-while-submitting"
         data-action="click->disable-while-submitting#click"></a>
    `;
    link = document.getElementById("link");
    clicks = 0;
  });

  it("lets the first click through and ignores the next ones", () => {
    link.click();
    link.click();
    link.click();

    expect(clicks).toBe(1);
    expect(link.getAttribute("aria-disabled")).toBe("true");
  });

  it("enables the link again when the submission ends", () => {
    link.click();
    document.dispatchEvent(new CustomEvent("turbo:submit-end"));
    expect(link.hasAttribute("aria-disabled")).toBe(false);

    link.click();
    expect(clicks).toBe(2);
  });
});
