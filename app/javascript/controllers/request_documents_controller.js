import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "firstPage",
    "secondPage",
    "checkbox",
    "input",
    "checkbox",
    "userSelect",
    "sendRequestButton",
  ];

  documentsRequestPresence =
    document.getElementById("documentsRequestPresence") != null;
  checklistItems = document.getElementsByClassName("checklist-item");

  connect() {
    this.secondPageTarget.hidden = true;
    // Added class in view and removing it from js to prevent
    // showing it before the JS connects to the DOM
    this.secondPageTarget.classList.remove("d-none");
    this.validateWithDocumentsRequest();
    this.initializeChecklistItems();
  }

  // Show first page and Hide second page
  backAction() {
    this.firstPageTarget.hidden = false;
    this.secondPageTarget.hidden = true;
  }

  // Show alert for user to know that the reminder is in progress
  async sendReminder(event) {
    event.preventDefault();

    const currentTarget = event.currentTarget;
    const userId = currentTarget.dataset.userId;
    const requestUrl = currentTarget.dataset.requestUrl;

    currentTarget.disabled = true;
    currentTarget.innerText = "Sending...";

    try {
      const response = await fetch(requestUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        },
        body: JSON.stringify({ user_id: userId }),
      });

      if (response.ok) {
        this.dispatch("showAlert", {
          detail: {
            message: "Email sent successfully.",
            type: "success",
          },
          target: currentTarget,
        });
      }
    } catch (error) {
      console.error(error);
    } finally {
      currentTarget.disabled = false;
      currentTarget.innerText = "Resend";
    }
  }

  // Validate if at least one checkbox was selected
  firstPageValidation() {
    return this.checkboxTargets.some((e) => e.checked);
  }

  // Initialize checklist items
  initializeChecklistItems() {
    this.checkboxTargets.forEach((e) => {
      let elementById = Array.from(this.checklistItems).find(
        (element) => element.id === e.id,
      );
      if (e.checked) {
        elementById.classList.remove("d-none");
        elementById.classList.add("d-flex");
      }
    });
  }

  // Remove checklist item with X icon
  removeItemFromChecklist(event) {
    const clickedItem = event.target.parentNode;
    const toggleItem = this.checkboxTargets.find(
      (element) => element.id === clickedItem.id,
    );
    toggleItem.click();
  }

  // Show/Remove checklist item
  renderChecklistItem(event) {
    const elementById = Array.from(this.checklistItems).find(
      (element) => element.id === event.target.id,
    );
    if (event.target.checked) {
      elementById.classList.remove("d-none");
      elementById.classList.add("d-flex");
    } else {
      elementById.classList.add("d-none");
      elementById.classList.remove("d-flex");
    }
  }

  // Hide first page and Show second page.
  nextAction() {
    if (!this.firstPageValidation()) {
      return alert("Please select at least one option.");
    }
    this.firstPageTarget.hidden = true;
    this.secondPageTarget.hidden = false;
  }

  // If select a user, disable the form inputs
  disableInputFields(event) {
    this.inputTargets.forEach((e) => (e.disabled = !!event.target.value));
    this.validateInputs();
  }

  // Validate checkboxes and inputs and enable/disable request button
  validateInputs() {
    const checkboxState = this.firstPageValidation();
    let inputState = this.inputTargets.every((e) => e.validity.valid);
    let selectValue = !!this.userSelectTarget.value;
    if (this.documentsRequestPresence) {
      inputState = true;
    }
    this.sendRequestButtonTarget.disabled = !(
      (inputState || selectValue) &&
      checkboxState
    );
  }

  // Validate inputs when documentsRequest is present
  validateWithDocumentsRequest() {
    if (this.documentsRequestPresence) {
      // Remove required attribute from inputs skip HTML validation
      this.inputTargets.forEach((e) => e.removeAttribute("required"));
    }
    const checkboxState = this.firstPageValidation();
    this.sendRequestButtonTarget.disabled = !checkboxState;
  }
}
