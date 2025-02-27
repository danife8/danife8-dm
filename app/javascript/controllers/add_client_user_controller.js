import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "userSelect", "addUserButton"];

  // If select a user, disable form inputs
  disableInputFields(event) {
    this.inputTargets.forEach((e) => (e.disabled = !!event.target.value));
    this.validateInputs();
  }

  // Validate checkboxes and inputs and enable/disable request button
  validateInputs() {
    let inputState = this.inputTargets.every((e) => e.validity.valid);
    let selectValue = !!this.userSelectTarget.value;
    this.addUserButtonTarget.disabled = !(inputState || selectValue);
  }
}
