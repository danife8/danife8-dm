import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="user-toggle-client-id"
export default class extends Controller {
  static targets = ["clientContainer"];

  targetUserRoleId = 0;

  connect() {
    this.targetUserRoleId = Number(this.element.dataset.targetUserRoleId);

    if (!this.targetUserRoleId)
      console.error("Error getting required data-target-user-role-id!");

    if (!this.hasClientContainerTarget)
      console.error(
        "Error getting required data-user-toggle-client-id-target='clientContainer'!",
      );
  }

  toggleClientContainer(event) {
    const selectedRoleId = Number(event.target.value);

    selectedRoleId === this.targetUserRoleId
      ? this.clientContainerTarget.classList.remove("d-none")
      : this.clientContainerTarget.classList.add("d-none");
  }
}
