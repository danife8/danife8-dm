import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="media-brief-form-step-5"
export default class extends Controller {
  static targets = ["form", "geographicFilters"];

  objectName = ""; // media_brief or media_brief_builder
  geographicFiltersCounter = 0;

  formTargetConnected() {
    this.objectName = this.formTarget.dataset.objectName;
  }

  geographicFiltersTargetConnected() {
    this.geographicFiltersCounter = Number(this.geographicFiltersTarget.value);
  }

  parseGeographicFilterLine(type, line) {
    if (line === undefined) {
      return {};
    }

    let parts = line.split(",").map((s) => s.trim());
    switch (type) {
      case "ZipcodeFilter":
        return { zipcode: line };
      case "CityStateFilter":
        return { city: parts[0] || "", state: parts[1] || "" };
      case "StateFilter":
        return { state: line };
      case "AddressFilter":
        let stateAndZipcode = (parts[2] || "").split(" ");
        let state = stateAndZipcode[0] || "";
        let zipcode = stateAndZipcode[1] || "";
        return {
          address: parts[0] || "",
          city: parts[1] || "",
          state: state,
          zipcode: zipcode,
        };
      default:
        console.log("Something went wrong...");
    }
  }

  addHiddenInput(index, field, value) {
    // Create a hidden input field and append it to the form
    const name = `${this.objectName}[geographic_filters_attributes][${index}][${field}]`;
    const hiddenInput = document.createElement("input");
    hiddenInput.type = "hidden";
    hiddenInput.name = name;
    hiddenInput.value = value;
    this.formTarget.appendChild(hiddenInput);
  }

  callBeforeSubmit() {
    // This is local to this step, each step can have their own version.
    // This will split geographic filter fields into a the nested attributes form.
    const fields = [
      "js-textbox-multi_state",
      "js-textbox-city_state",
      "js-textbox-georadius",
      "js-textbox-zip",
      "js-textbox-address",
      "js-textbox-local_city_state",
    ];
    let fieldCounter = 0;

    fields.forEach((field) => {
      let textArea = document.querySelector(`.${field}`);
      if (!textArea || textArea.disabled) return null;

      const geographicFilterType = textArea.dataset.geographicFilterType;
      // Add hidden input fields for each line
      const lines = textArea.value.split("\n");
      if (!lines.length) return null;

      lines.forEach((line) => {
        line = line.trim();
        if (!line) return null;

        let parsedGeographicFilter = this.parseGeographicFilterLine(
          geographicFilterType,
          line,
        );
        Object.entries(parsedGeographicFilter).forEach(([fieldName, value]) => {
          this.addHiddenInput(
            fieldCounter + this.geographicFiltersCounter,
            fieldName,
            value,
          );
        });
        this.addHiddenInput(
          fieldCounter + this.geographicFiltersCounter,
          "type",
          geographicFilterType,
        );
        fieldCounter += 1;
      });
    });
  }

  submit(event) {
    event.preventDefault();
    this.callBeforeSubmit();
    this.formTarget.submit();
  }
}
