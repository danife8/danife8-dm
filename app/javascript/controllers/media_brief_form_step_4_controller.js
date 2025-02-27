import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="media-brief-form-step-4"
export default class extends Controller {
  static targets = ["ageCheckbox", "genderCheckbox"];

  onChangeAllDemographics(event) {
    const checkboxes = [
      ...this.ageCheckboxTargets,
      ...this.genderCheckboxTargets,
    ];
    this.cleanCheckboxes(checkboxes, event.currentTarget.checked);
  }

  onChangeAllGenders(event) {
    const checkboxes = this.genderCheckboxTargets.filter(
      (e) => e !== event.currentTarget,
    );
    this.cleanCheckboxes(checkboxes, event.currentTarget.checked);
  }

  onChangeAllAges(event) {
    const checkboxes = this.ageCheckboxTargets.filter(
      (e) => e !== event.currentTarget,
    );
    this.cleanCheckboxes(checkboxes, event.currentTarget.checked);
  }

  // Disables or enables a list of checkboxes based on the state of the controlling checkbox.
  // When the controlling checkbox (e.g., "All ages") is checked, it also unchecks the other age checkboxes, as they are covered by "All ages"
  cleanCheckboxes(checkboxes = [], isTargetChecked = false) {
    checkboxes.forEach((checkbox) => {
      checkbox.disabled = isTargetChecked;
      if (isTargetChecked) checkbox.checked = false;
    });
  }

  submit() {}
}
