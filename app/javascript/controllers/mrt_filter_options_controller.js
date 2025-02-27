import { Controller } from "@hotwired/stimulus";

const fields = {
  campaignChannel: {
    fieldName: "campaign_channel",
    filters: ["campaignChannel"],
    dependentFields: ["mediaPlatform", "targetStrategy", "target", "adFormat"],
  },
  mediaPlatform: {
    fieldName: "media_platform",
    filters: ["campaignChannel", "mediaPlatform"],
    dependentFields: ["targetStrategy", "target", "adFormat"],
  },
  targetStrategy: {
    fieldName: "target_strategy",
    filters: ["campaignChannel", "mediaPlatform", "targetStrategy"],
    dependentFields: ["target", "adFormat"],
  },
  target: {
    fieldName: "target",
    filters: ["campaignChannel", "mediaPlatform", "targetStrategy", "target"],
    dependentFields: ["adFormat"],
  },
  adFormat: {
    fieldName: "ad_format",
    filters: [
      "campaignChannel",
      "mediaPlatform",
      "targetStrategy",
      "target",
      "adFormat",
    ],
    dependentFields: [],
  },
};

// Connects to data-controller="mrt-filter-options"
export default class extends Controller {
  static targets = Object.keys(fields);

  campaignObjectiveId = "";
  campaignInitiativeId = "";
  url = "";

  connect() {
    const { campaignObjectiveId, campaignInitiativeId, url } =
      this.element.dataset;

    this.campaignObjectiveId = campaignObjectiveId;
    this.campaignInitiativeId = campaignInitiativeId;
    this.url = url;

    if (!this.campaignObjectiveId || !this.campaignInitiativeId || !this.url) {
      console.error(
        "Error getting required data-campaign-objective-id, data-campaign-initiative-id, or data-url!",
      );
    }
  }

  async handleOptions(target, filters) {
    const url = `${this.url}?${new URLSearchParams(filters).toString()}`;

    this.setDisabled(target, true);
    const options = await this.fetchOptions(url);
    this.setDisabled(target, false);
    this.populateOptions(target, options);
  }

  async fetchOptions(url) {
    try {
      const headers = {
        Accept: "application/json",
        "Content-Type": "application/json",
      };
      const response = await fetch(url, { headers: headers });
      const parsedResponse = await response.json();
      return parsedResponse.filtered_options;
    } catch (e) {
      console.error("Error getting options!", e);
      return [];
    }
  }

  generateOption(value = "", label = "") {
    return `<option value='${value}'>${label}</option>`;
  }

  setDisabled(target, isDisabled) {
    target.disabled = isDisabled;
  }

  populateOptions(target, options) {
    const placeholderEl = target.querySelector("option")?.outerHTML || "";
    target.innerHTML = placeholderEl; // Clean old options
    if (!options || !options.length) return;

    let optionsStr = target.innerHTML;

    options.forEach((item) => {
      const option = this.generateOption(item.id, item.label);
      optionsStr += option;
    });
    target.innerHTML = optionsStr;
  }

  findTargetElFromRow(targetName, rowEl) {
    const allResults = this.targets.findAll(targetName);
    return allResults.find((el) => el.closest("tr") === rowEl);
  }

  onChange(event) {
    const sourceFieldName = event.target.dataset.mrtFilterOptionsTarget;
    const { dependentFields, filters } = fields[sourceFieldName];
    const parentRow = event.target.closest("tr");

    if (!dependentFields || !dependentFields.length) return;

    const [targetFieldName] = dependentFields; // Grab the first field name
    const targetFieldEl = this.findTargetElFromRow(targetFieldName, parentRow);
    const targetFieldData = fields[targetFieldName];

    this.resetFields(dependentFields, parentRow);
    const filtersObj = this.getFilters(
      filters,
      targetFieldData.fieldName,
      parentRow,
    );
    this.handleOptions(targetFieldEl, filtersObj);
  }

  getFilters(fieldNames, targetFieldName, parentRow) {
    if (!fieldNames || !targetFieldName) {
      return {};
    }

    const filters = {
      campaign_objective_id: this.campaignObjectiveId,
      campaign_initiative_id: this.campaignInitiativeId,
      target_field_name: targetFieldName,
    };

    fieldNames.forEach((fieldName) => {
      const reference = this.findTargetElFromRow(fieldName, parentRow);
      if (!reference || !fields[fieldName]) return;

      const key = `${fields[fieldName]["fieldName"]}_id`;
      filters[key] = reference.value;
    });

    return filters;
  }

  resetFields(fieldNames, parentRow) {
    if (!fieldNames || !fieldNames.length) return;

    fieldNames.forEach((fieldName) => {
      const reference = this.findTargetElFromRow(fieldName, parentRow);
      if (!reference) return;

      reference.disabled = true;
      reference.value = "";
    });
  }
}
