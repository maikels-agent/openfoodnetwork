/**
 * @jest-environment jsdom
 */

import { Application } from "stimulus";
import filter_rows_controller from "../../../app/webpacker/controllers/filter_rows_controller";

describe("FilterRowsController", () => {
  beforeAll(() => {
    const application = Application.start();
    application.register("filter-rows", filter_rows_controller);
  });

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="filter-rows">
        <input id="query" data-filter-rows-target="query" data-action="input->filter-rows#filter" />
        <input id="toggle" type="checkbox" data-action="filter-rows#toggleKeyword"
          data-filter-rows-keyword-param="manage_products" />
        <table>
          <tr id="apple" data-filter-rows-target="row" data-filter-rows-keywords="manage_products">
            <td>Apple Farm</td><td>Fruit Hub</td>
          </tr>
          <tr id="berry" data-filter-rows-target="row">
            <td>Berry Farm</td><td>Fruit Hub</td>
          </tr>
        </table>
      </div>`;
  });

  const search = (value) => {
    const query = document.getElementById("query");
    query.value = value;
    query.dispatchEvent(new Event("input"));
  };
  const hidden = (id) => document.getElementById(id).hidden;

  it("shows all rows without a query", () => {
    search("");

    expect(hidden("apple")).toBe(false);
    expect(hidden("berry")).toBe(false);
  });

  it("hides rows not containing the query", () => {
    search("apple");

    expect(hidden("apple")).toBe(false);
    expect(hidden("berry")).toBe(true);
  });

  it("requires all words to match, in any order and case", () => {
    search("HUB berry");

    expect(hidden("apple")).toBe(true);
    expect(hidden("berry")).toBe(false);
  });

  it("matches keywords which are not part of the text", () => {
    search("manage_products");

    expect(hidden("apple")).toBe(false);
    expect(hidden("berry")).toBe(true);
  });

  it("toggles keywords in the query", () => {
    const query = document.getElementById("query");
    const toggle = document.getElementById("toggle");
    search("farm");

    toggle.click();

    expect(query.value).toBe("farm manage_products");
    expect(hidden("apple")).toBe(false);
    expect(hidden("berry")).toBe(true);

    toggle.click();

    expect(query.value).toBe("farm");
    expect(hidden("berry")).toBe(false);
  });

  it("filters rows added later", () => {
    search("apple");

    document
      .querySelector("table")
      .insertAdjacentHTML(
        "beforeend",
        `<tr id="cherry" data-filter-rows-target="row"><td>Cherry Farm</td></tr>`,
      );

    return Promise.resolve().then(() => {
      expect(hidden("cherry")).toBe(true);
    });
  });
});
