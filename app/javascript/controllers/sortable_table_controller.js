import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="sortable-table"
export default class extends Controller {
  static targets = [
    "table",
    "discardButton",
    "saveButton",
    "hiddenFieldsContainer",
    "row",
  ];

  hiddenFieldName = "";
  initialSerializedRows = [];

  hiddenFieldsContainerTargetConnected() {
    this.hiddenFieldName =
      this.hiddenFieldsContainerTarget.dataset.hiddenFieldName;
    if (!this.hiddenFieldName)
      console.error("Error getting required data-hidden-field-name!");
  }

  tableTargetConnected() {
    // No sortable items
    if (!this.hasRowTarget) return;

    window.sortable(this.tableTarget, {
      items: ".js-sortable-row",
      hoverClass: "sortable-hovered",
      placeholder:
        "<tr class='sortable-placeholder'><td colspan='9'><span>&nbsp</span></td></tr>",
      itemSerializer: (serializedRow) => ({
        id: serializedRow.node.dataset.id,
        newPriority: serializedRow.index + 1,
        oldPriority: Number(serializedRow.node.dataset.priority),
        row: serializedRow.node.cloneNode(true), // Better performance when cloning
      }),
    });

    this.initialSerializedRows = this.serializeSortableTable();

    window.sortable(this.tableTarget)[0].addEventListener("sortupdate", () => {
      const serializedRows = this.serializeSortableTable();
      const shouldEnableButtons = serializedRows.some(
        (row) => row.newPriority !== row.oldPriority,
      );
      this.enableButtons(shouldEnableButtons);
      this.setHiddenFieldsValues(serializedRows);
    });
  }

  serializeSortableTable() {
    return window.sortable(this.tableTarget, "serialize")?.at(0)?.items || [];
  }

  enableButtons(shouldEnable) {
    this.saveButtonTarget.disabled = !shouldEnable;
    this.discardButtonTarget.disabled = !shouldEnable;
  }

  createHiddenField(value) {
    return `<input type="hidden" name="${this.hiddenFieldName}[]" value="${value}" autocomplete="off">`;
  }

  setHiddenFieldsValues(rows) {
    let newValues = "";
    rows.forEach(({ id }) => (newValues += this.createHiddenField(id)));
    this.hiddenFieldsContainerTarget.innerHTML = newValues;
  }

  getOptimizedRows() {
    // Create a DocumentFragment to hold new nodes and optimize performance by causing just a single reflow
    const fragment = document.createDocumentFragment();
    this.initialSerializedRows.forEach(({ row }) => fragment.appendChild(row));
    return fragment;
  }

  onDiscard() {
    // Discard modified rows
    this.rowTargets.forEach((row) => row.remove());
    // Restore initial rows
    this.tableTarget.prepend(this.getOptimizedRows());
    // Reinitialize the sortable functionality
    window.sortable(this.tableTarget, "reload");
    this.enableButtons(false);
    this.setHiddenFieldsValues([]);
    // Communicate with other controllers. Please refer to https://stimulus.hotwired.dev/reference/controllers#cross-controller-coordination-with-events
    this.dispatch("showAlert", {
      detail: {
        message: "The priority changes have been successfully discarded.",
        type: "success",
      },
    });
  }

  onSubmit(event) {
    event.preventDefault();
    const isConfirmed = confirm(
      "The priorities were modified. Are you sure you want to save changes?",
    );
    const form = event.target.closest("form");
    if (isConfirmed) form.submit();
  }
}
