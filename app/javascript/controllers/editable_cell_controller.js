import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="editable-cell"
export default class extends Controller {
  static targets = ["text", "input"];

  static values = {
    original: String,
    modified: Boolean,
  };

  static classes = ["modified"];

  isSelectTag = false;

  inputTargetConnected() {
    if (this.inputTarget instanceof HTMLSelectElement) {
      this.isSelectTag = true;
    }
  }

  getTextValue() {
    if (this.isSelectTag) {
      return this.inputTarget.querySelector("option:checked").text;
    }
    return this.inputTarget.value;
  }

  toggleField() {
    if (this.textTarget.style.display !== "none") {
      // Hide text and show input field
      this.textTarget.style.display = "none";
      this.inputTarget.style.display = "block";
      this.inputTarget.focus();
    }
  }

  hideField() {
    const isValid = this.inputTarget.checkValidity();
    this.inputTarget.classList.remove("input-error");

    if (!isValid) {
      this.inputTarget.classList.add("input-error");
      return;
    }

    // Hide input and show text
    this.inputTarget.style.display = "none";
    this.textTarget.style.display = "block";
    this.textTarget.innerHTML = this.getTextValue();

    const modified = this.originalValue !== this.inputTarget.value;
    modified
      ? this.element.classList.add(this.modifiedClass)
      : this.element.classList.remove(this.modifiedClass);

    // Update attr data-editable-cell-modified-value
    this.modifiedValue = modified;
    this.dispatch("blur"); // Communicate with other controllers
  }
}
