import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="media-brief-form-step-2"
export default class extends Controller {
  static targets = ["form", "destinationField"];

  errors = {
    required: "Please fill out this field",
    pattern: "Please follow the example formatting",
  };

  checkFieldValidity(field) {
    return field.validity.valid;
  }

  handleValidation(field) {
    const isValid = this.checkFieldValidity(field);
    const errorContainer = field.parentElement.querySelector(".js-error");
    field.parentElement.classList.remove("invalid-field");

    if (!isValid) {
      field.parentElement.classList.add("invalid-field");
      if (errorContainer)
        errorContainer.textContent = field.validity.valueMissing
          ? this.errors.required
          : this.errors.pattern;
    }
  }

  prependProtocolToURL(event) {
    const { value } = event.target;
    const protocolRegExp = /^(https?:\/\/)/;

    if (value && !protocolRegExp.test(value)) {
      event.target.value = `http://${value}`;
    }

    this.handleValidation(event.target);
  }

  submit(event) {
    event.preventDefault();
    const isValid = this.checkFieldValidity(this.destinationFieldTarget);

    if (isValid) {
      this.formTarget.submit();
    }
  }
}
