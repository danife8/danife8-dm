import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="geographic-target"
export default class extends Controller {
  static values = {
    mainMap: Object,
    subMap: Object,
  };

  connect() {
    this.mainElements = this.extractUniqueElements(this.mainMapValue);
    this.subElements = this.extractUniqueElements(this.subMapValue);
  }

  extractUniqueElements(map) {
    const allElements = Object.values(map).flat();
    return [...new Set(allElements)];
  }

  onChange(event) {
    const isMainDropdown = event.target.dataset.targetType === "main";
    const targetValue = event.target.value;
    const currentMap = isMainDropdown ? this.mainMapValue : this.subMapValue;
    const allElements = isMainDropdown
      ? [...this.mainElements, ...this.subElements]
      : this.subElements;

    this.updateElementVisibility(allElements, true);
    const elementsToShow = currentMap[targetValue] || [];
    this.updateElementVisibility(elementsToShow, false);
  }

  updateElementVisibility(elements, shouldHide) {
    elements.forEach((id) => {
      const element = this.findElementByClass(id);
      if (!element) return;

      const parent = element.closest(".js-field-container");
      if (parent) {
        parent.classList.toggle("d-none", shouldHide);
      }
      this.disableElement(element, shouldHide);
    });
  }

  findElementByClass(className) {
    return document.querySelector(`.js-${className}`);
  }

  disableElement(element, disable) {
    if (disable) element.value = "";
    element.disabled = disable;
  }
}
