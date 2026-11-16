import { Controller } from "stimulus";

// Loads a Turbo Frame from a URL which depends on the value of a form field.
//
//   %div{ data: { controller: "frame-loader", "frame-loader-url-value": "/details",
//                 "frame-loader-param-value": "id" } }
//     %select{ data: { action: "change->frame-loader#load" } }
//     %template{ data: { "frame-loader-target": "loading" } }
//       Loading...
//     %turbo-frame#details{ data: { "frame-loader-target": "frame" } }
//
// Selecting the option "7" loads the frame from `/details?id=7`. The frame is
// emptied when the field is blank. The loading template is optional.
export default class extends Controller {
  static targets = ["frame", "loading"];
  static values = { url: String, param: String };

  load(event) {
    const value = event.target.value;

    if (!value) {
      this.frameTarget.removeAttribute("src");
      this.frameTarget.innerHTML = "";
      return;
    }

    if (this.hasLoadingTarget) {
      this.frameTarget.innerHTML = this.loadingTarget.innerHTML;
    }

    const url = new URL(this.urlValue, window.location.origin);
    url.searchParams.set(this.paramValue, value);
    this.frameTarget.setAttribute("src", url.toString());
  }
}
