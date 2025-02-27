import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="autogenerate-value"
export default class extends Controller {
  static targets = ["source", "target"];

  generateValue(label) {
    const normalizedValue = label
      .toLowerCase()
      .replace(/ /g, "_")
      .replace(/[^a-z0-9_]/g, "");
    return normalizedValue;
  }

  onChangeSource(event) {
    const normalizedValue = this.generateValue(event.target.value);
    this.targetTarget.value = normalizedValue;
  }
}
