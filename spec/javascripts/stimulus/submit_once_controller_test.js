/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import submit_once_controller from "../../../app/webpacker/controllers/submit_once_controller";

describe("SubmitOnceController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("submit-once", submit_once_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <form id="form" data-controller="submit-once" data-action="submit@window->submit-once#guard">
      </form>
      <form id="other"></form>`;
  });

  // Returns true if the form would have been submitted.
  const submit = (id, listener) => {
    const form = document.getElementById(id);
    if (listener) form.addEventListener("submit", listener, { once: true });

    return form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
  };

  it("allows submitting only once", () => {
    expect(submit("form")).toBe(true);
    expect(submit("form")).toBe(false);
    expect(document.getElementById("form").classList).toContain("submitted");
  });

  it("ignores submissions cancelled by others", () => {
    expect(submit("form", (event) => event.preventDefault())).toBe(false);
    expect(
      submit("form", (event) => {
        event.preventDefault();
        event.stopPropagation();
      }),
    ).toBe(false);

    expect(submit("form")).toBe(true);
    expect(submit("form")).toBe(false);
  });

  it("ignores other forms", () => {
    expect(submit("other")).toBe(true);
    expect(submit("other")).toBe(true);
    expect(submit("form")).toBe(true);
  });
});
