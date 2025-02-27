import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="editable-row"
export default class extends Controller {
  static targets = ["button", "cell"];

  isModified() {
    const cells = [...this.cellTargets];
    return cells
      .map((cell) => cell.dataset.editableCellModifiedValue === "true")
      .some(Boolean);
  }

  setButtonState() {
    // We can have a general form button or a button per row, so this is optional.
    if (!this.hasButtonTarget) return;
    this.buttonTarget.disabled = !this.isModified();
  }
}
