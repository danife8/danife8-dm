import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="media-plan-row"
export default class extends Controller {
  static targets = ["row", "template", "container"];

  add() {
    const newRow = this.templateTarget.content.cloneNode(true).children[0]; // Grab tr from template
    newRow.dataset.mediaPlanRowTarget = "row";
    const newIndex = this.rowTargets.length;

    newRow.querySelectorAll("input, select").forEach((input) => {
      input.name = input.name.replace(/NEW_ROW/, newIndex);
    });

    // Inject new row
    this.containerTarget.insertBefore(
      newRow,
      this.containerTarget.lastElementChild,
    );

    this.dispatch("addRow");
  }
}
