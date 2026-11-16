import { Controller } from "stimulus";

// Filters a list of rows on the client side.
//
// A row is shown if it contains all words of the query. Words are matched
// against the row's text, or against `data-filter-rows-keywords` if present.
// Keywords are useful when the row contains form fields.
//
//   %div{ "data-controller": "filter-rows" }
//     %input{ "data-filter-rows-target": "query", "data-action": "input->filter-rows#filter" }
//     %input{ type: "checkbox", "data-action": "filter-rows#toggleKeyword",
//             "data-filter-rows-keyword-param": "green" }
//     %table
//       %tr{ "data-filter-rows-target": "row", "data-filter-rows-keywords": "green" }
//
export default class extends Controller {
  static targets = ["query", "row"];

  filter() {
    const words = this.#words();

    this.rowTargets.forEach((row) => {
      row.hidden = !this.#matches(row, words);
    });
  }

  // Add the keyword to the query, or remove it if it's already there.
  toggleKeyword(event) {
    const keyword = event.params.keyword.toLowerCase();
    const words = this.#words();
    const index = words.indexOf(keyword);

    if (index > -1) {
      words.splice(index, 1);
    } else {
      words.push(keyword);
    }

    this.queryTarget.value = words.join(" ");
    this.filter();
  }

  // Rows added later, for example via Turbo Stream, need filtering too.
  rowTargetConnected(row) {
    row.hidden = !this.#matches(row, this.#words());
  }

  // private

  #words() {
    return this.queryTarget.value.toLowerCase().split(/\s+/).filter(Boolean);
  }

  #matches(row, words) {
    const text = (row.dataset.filterRowsKeywords ?? row.textContent).toLowerCase();

    return words.every((word) => text.includes(word));
  }
}
