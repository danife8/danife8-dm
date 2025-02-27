import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="dependent-dropdowns"
export default class extends Controller {
  static targets = ["source", "target"];

  optionsUrl = "";
  optionsKey = "";
  optionLabel = "";
  optionValue = "";

  sourceTargetConnected() {
    const {
      optionsUrl,
      optionsKey,
      optionLabelAttr = "label",
      optionValueAttr = "id",
    } = this.sourceTarget.dataset;

    this.optionsUrl = optionsUrl;
    this.optionsKey = optionsKey;
    this.optionLabel = optionLabelAttr;
    this.optionValue = optionValueAttr;

    if (!this.optionsUrl)
      console.error("Error getting required data-options-url!");
    if (!this.optionsKey)
      console.error("Error getting required data-options-key!");
  }

  async fetchOptionsByValue(sourceValue) {
    if (!sourceValue) return;
    const url = this.optionsUrl.replace("placeholder_id", sourceValue);

    try {
      const headers = {
        Accept: "application/json",
        "Content-Type": "application/json",
      };
      const response = await fetch(url, { headers: headers });
      const parsedResponse = await response.json();
      return parsedResponse[this.optionsKey];
    } catch (e) {
      console.error("Error getting options!", e);
      return [];
    }
  }

  generateOption(value = "", label = "") {
    return `<option value='${value}'>${label}</option>`;
  }

  setLoading(isLoading) {
    this.targetTarget.innerHTML = this.generateOption(
      "",
      isLoading ? "Loading..." : "",
    );
  }

  populateOptions(options) {
    this.targetTarget.innerHTML = this.generateOption(); // Clean old options
    if (!options || !options.length) return;

    let optionsStr = this.targetTarget.innerHTML;
    options.forEach((item) => {
      const option = this.generateOption(
        item[this.optionValue],
        item[this.optionLabel],
      );
      optionsStr += option;
    });
    this.targetTarget.innerHTML = optionsStr;
  }

  async handleOptions(sourceValue) {
    if (!sourceValue) return this.populateOptions();

    this.setLoading(true);
    const options = await this.fetchOptionsByValue(sourceValue);
    this.setLoading(false);
    this.populateOptions(options);
  }

  onChangeSource(event) {
    this.handleOptions(event.target.value);
  }
}
