import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="alert"
export default class extends Controller {
  static targets = ["container"];

  createAlert(message, type) {
    const alert = document.createElement("div");
    alert.classList.add("alert", `alert-${type}`, "alert-dismissible", "mb-0");
    alert.setAttribute("role", "alert");

    const messageBox = document.createElement("div");
    messageBox.textContent = message;
    alert.appendChild(messageBox);

    const closeButton = document.createElement("button");
    closeButton.setAttribute("type", "button");
    closeButton.classList.add("btn-close");
    closeButton.setAttribute("data-bs-dismiss", "alert");
    closeButton.setAttribute("aria-label", "Close");
    alert.appendChild(closeButton);

    return alert;
  }

  insertAlert(message, type) {
    const alert = this.createAlert(message, type);
    this.containerTarget.append(alert);
  }

  backToTop() {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  show({ detail }) {
    const { message, type = "success" } = detail;
    if (!message)
      return console.error("Error getting required message parameter!");

    this.insertAlert(message, type);
    this.backToTop();
  }
}
