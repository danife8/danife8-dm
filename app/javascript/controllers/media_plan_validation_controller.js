import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "rejectComment",
    "approveComment",
    "rejectModal",
    "approveModal",
  ];

  connect() {
    this.rejectModalTarget.addEventListener(
      "show.bs.modal",
      this.handleRejectModalOpen.bind(this),
    );

    this.rejectModalTarget.addEventListener(
      "hidden.bs.modal",
      this.makeOptional.bind(this, this.rejectCommentTarget),
    );

    this.approveModalTarget.addEventListener(
      "show.bs.modal",
      this.handleApproveModalOpen.bind(this),
    );

    this.approveModalTarget.addEventListener(
      "hidden.bs.modal",
      this.makeOptional.bind(this, this.approveCommentTarget),
    );
  }

  makeOptional(el) {
    el.removeAttribute("required");
  }

  makeRequired(el) {
    el.setAttribute("required", "true");
  }

  handleRejectModalOpen() {
    this.makeRequired(this.rejectCommentTarget);
    this.makeOptional(this.approveCommentTarget);
  }

  handleApproveModalOpen() {
    this.makeRequired(this.approveCommentTarget);
    this.makeOptional(this.rejectCommentTarget);
  }
}
