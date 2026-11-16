/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import frame_loader_controller from "../../../app/webpacker/controllers/frame_loader_controller";

describe("FrameLoaderController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("frame-loader", frame_loader_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="frame-loader" data-frame-loader-url-value="/details?page=1"
        data-frame-loader-param-value="id">
        <select id="select" data-action="change->frame-loader#load">
          <option value=""></option>
          <option value="7">Seven</option>
        </select>
        <template data-frame-loader-target="loading">Loading...</template>
        <turbo-frame id="frame" data-frame-loader-target="frame">Old content</turbo-frame>
      </div>`;
  });

  const select = (value) => {
    const select = document.getElementById("select");
    select.value = value;
    select.dispatchEvent(new Event("change"));
  };

  it("loads the frame with the selected value", () => {
    select("7");

    const frame = document.getElementById("frame");
    expect(frame.getAttribute("src")).toBe("http://localhost/details?page=1&id=7");
    expect(frame.textContent).toBe("Loading...");
  });

  it("empties the frame without a value", () => {
    select("7");
    select("");

    const frame = document.getElementById("frame");
    expect(frame.hasAttribute("src")).toBe(false);
    expect(frame.textContent).toBe("");
  });
});
