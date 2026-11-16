import { Controller } from "stimulus";
import TomSelect from "tom-select/dist/esm/tom-select.complete";
import showHttpError from "js/services/show_http_error";

// Select a user by searching for their email address.
//
// By default, it offers to enter any email address, for example to invite a
// new user. To choose an existing user by id:
//
//   = f.select :owner_id, [[owner.email, owner.id]], {},
//     data: { controller: "select-user", "select-user-value-field-value": "id",
//             "select-user-create-value": false }
//
export default class extends Controller {
  static values = {
    create: { type: Boolean, default: true },
    valueField: { type: String, default: "email" },
  };

  connect() {
    this.control = new TomSelect(this.element, {
      create: this.createValue,
      plugins: ["dropdown_input"],
      labelField: "email",
      load: this.#load.bind(this),
      maxItems: 1,
      persist: false,
      searchField: ["email"],
      shouldLoad: (query) => query.length > 2,
      valueField: this.valueFieldValue,
    });
  }

  disconnect() {
    if (this.control) this.control.destroy();
  }

  // private

  #load(query, callback) {
    const url = "/admin/search/known_users.json?q=" + encodeURIComponent(query);
    fetch(url)
      .then((response) => {
        if (!response.ok) {
          showHttpError(response.status);
          throw response;
        }
        return response.json();
      })
      .then((json) => {
        callback({ items: json });
      })
      .catch((error) => {
        console.log(error);
        callback();
      });
  }
}
