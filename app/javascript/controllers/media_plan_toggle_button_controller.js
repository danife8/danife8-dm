import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="media-plan-toggle-button"
export default class extends Controller {
  static targets = [
    "input",
    "checkbox",
    "updateButton",
    "rejectButton",
    "approveButton",
  ];

  allowTogging = true;

  connect() {
    this.allowTogging = this.element.dataset.errorsOnNewRows === "false";
  }

  toggle(shouldHide) {
    // ShouldHide: Determine whether the class is included or not
    this.updateButtonTarget.classList.toggle("d-none", !shouldHide);
    this.rejectButtonTarget.classList.toggle("d-none", shouldHide);
    this.approveButtonTarget.classList.toggle("d-none", shouldHide);
  }

  hasChanges() {
    // The editable-cell-modified-value attr comes out of the box with the editable cell feature
    const inputsChanged = this.inputTargets.some(
      (input) =>
        input.closest("td").dataset.editableCellModifiedValue === "true",
    );
    const checkboxesChanged = this.checkboxTargets.some(
      (checkbox) => checkbox.checked !== checkbox.defaultChecked,
    );

    return inputsChanged || checkboxesChanged;
  }

  toggleButtons() {
    if (!this.allowTogging) return;

    const hasChanges = this.hasChanges();
    this.toggle(hasChanges);
  }

  showUpdateButton() {
    if (!this.allowTogging) return;

    this.toggle(true);
    this.allowTogging = false;
  }
}
