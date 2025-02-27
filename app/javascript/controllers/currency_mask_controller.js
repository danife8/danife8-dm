import { Controller } from "@hotwired/stimulus";
import IMask from "imask";

export default class extends Controller {
  newInput = "";
  mask = "";
  precision = 0;
  maskPattern = "$num";

  connect() {
    this.element.type = "text";
    const name = this.element.name;
    const form = this.element.getAttribute("form");

    if (this.element.dataset.currencyMaskPrecision) {
      this.precision = parseInt(this.element.dataset.currencyMaskPrecision);
    }

    if (this.element.dataset.currencyMaskPattern) {
      this.maskPattern = this.element.dataset.currencyMaskPattern;
    }

    this.newInput = document.createElement("input");
    this.newInput.type = "hidden";
    this.newInput.value = this.formatValue(this.element.value);
    this.newInput.name = name;
    this.newInput.setAttribute("form", form);
    this.element.name = "";

    this.element.insertAdjacentElement("afterend", this.newInput);

    this.mask = IMask(this.element, {
      mask: this.maskPattern,
      blocks: {
        num: {
          mask: Number,
          scale: this.precision, // digits after point, 0 for integers
          thousandsSeparator: ",",
          radix: ".",
          autofix: true,
          normalizeZeros: !!this.precision,
          padFractionalZeros: !!this.precision,
        },
      },
    });
  }

  formatValue(value) {
    return parseFloat(value).toFixed(this.precision);
  }

  onChange() {
    const formattedValue = this.formatValue(this.mask.unmaskedValue);
    this.newInput.value = formattedValue;
  }
}
