import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="media-plan-update-state"
export default class extends Controller {
  static targets = ["action"];

  submit(event) {
    const actionValue = event.target.dataset.actionValue;
    this.actionTarget.value = actionValue;
  }
}
