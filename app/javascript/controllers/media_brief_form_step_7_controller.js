import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="media-brief-form-step-5"
export default class extends Controller {
  connect() {
    document
      .querySelectorAll(".js-creative-asset")
      .forEach(this.toggleCheckbox);
  }

  onChange(event) {
    const element = event.target;
    this.toggleCheckbox(element, element.dataset.index);
  }

  toggleCheckbox(element, index) {
    const campaign = document.querySelectorAll(".js-campaign-channel")[index];
    campaign.checked = false;
    campaign.disabled = element.checked;
  }

  submit() {}
}
