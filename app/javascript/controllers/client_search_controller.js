import { Controller } from "@hotwired/stimulus"

// Debounced search controller for client list filtering.
// Automatically submits the search form after a brief pause in typing.
//
// Usage:
//   <form data-controller="client-search"
//         data-client-search-debounce-value="300">
//     <input type="text" data-action="input->client-search#search">
//     <select data-action="change->client-search#search">
//   </form>
export default class extends Controller {
  static values = {
    debounce: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  // Debounced search - waits for typing to pause before submitting
  search() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, this.debounceValue)
  }

  // Immediate submit for select changes (no debounce needed)
  submit() {
    this.element.requestSubmit()
  }
}
