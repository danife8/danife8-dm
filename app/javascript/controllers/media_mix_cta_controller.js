import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="slider-table"
export default class extends Controller {
  static targets = ["showDetailsBtn", "sliderDetails", "finalOutput"];

  connect() {
    this.showDetailsBtnTarget.innerHTML = "Show Details";

    this.showDetailsBtnTarget.addEventListener("click", () =>
      this.toggleDetails(),
    );
  }

  toggleDetails() {
    const action = this.finalOutputTarget.classList.contains("d-none")
      ? "show"
      : "hide";
    this.showDetailsBtnTarget.innerHTML =
      action == "show" ? "Show Details" : "Hide Details";

    this.finalOutputTarget.classList.toggle("d-none");
    this.sliderDetailsTarget.classList.toggle("d-none");
  }
}
