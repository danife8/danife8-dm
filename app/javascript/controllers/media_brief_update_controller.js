import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"];
  hasChanged = false;

  connect() {
    this.element
      .querySelectorAll("input, textarea, select")
      .forEach((input) => {
        input.addEventListener("change", () => {
          this.hasChanged = true;
        });
      });
  }

  submit(event) {
    if (this.hasChanged) {
      const confirmed = confirm(
        "You are about to change information that will impact " +
          "Media Mixes and Media Plans generated using an old version of this Media Brief. " +
          "\nDo you want to proceed?",
      );

      if (!confirmed) {
        event.preventDefault();
        return;
      }
    }

    this.hasChanged = false;
  }
}
