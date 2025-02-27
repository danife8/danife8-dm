// app/javascript/controllers/file_upload_controller.js

import { Controller } from "@hotwired/stimulus";
import { DirectUpload } from "@rails/activestorage";

export default class extends Controller {
  static targets = ["fileInput", "fileList", "fileUploadButton"];
  files = [];

  connect() {
    this.updateFileUploadButton();
    this.element.addEventListener("dragover", this.preventDragDefaults);
    this.element.addEventListener("dragenter", this.preventDragDefaults);
  }
  // Prevent default behavior of drag and drop files in browser
  preventDragDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
  }

  // Trigger click action for the hidden input
  trigger() {
    this.element.querySelector("input[type=file]").click();
  }

  // Validate and load files from the choose file button
  selectFiles() {
    const selectedFiles = Array.from(this.fileInputTarget.files);
    selectedFiles.forEach((file) => {
      if (this.isValidFile(file)) {
        this.files.push(file);
        this.selectedFilesDefaultActions();
      } else {
        alert(file.name + " is not a valid file.");
      }
    });
  }

  // Validate and load dropped files
  acceptFiles(event) {
    event.preventDefault();
    const droppedFiles = Array.from(event.dataTransfer.files);
    droppedFiles.forEach((file) => {
      if (this.isValidFile(file)) {
        this.files.push(file);
        this.selectedFilesDefaultActions();
      } else {
        alert(file.name + " is not a valid file.");
      }
    });
  }

  // File validator
  isValidFile(file) {
    const allowedTypes = [
      "application/msword",
      "application/pdf",
      "application/zip",
      "application/vnd.adobe.photoshop",
      "application/vnd.ms-excel",
      "application/vnd.ms-powerpoint",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "audio/mpeg",
      "audio/wav",
      "image/bmp",
      "image/gif",
      "image/jpeg",
      "image/png",
      "image/tiff",
      "image/vnd.adobe.photoshop",
      "image/webp",
      "image/x-icon",
      "text/csv",
      "text/plain",
      "video/mp4",
      "video/quicktime",
      "video/webm",
      "video/x-flv",
      "video/x-m2ts",
      "video/x-ms-wmv",
      "video/x-msvideo",
    ];
    const maxSizeInBytes = 25 * 1024 * 1024; // 25MB

    return allowedTypes.includes(file.type) && file.size <= maxSizeInBytes;
  }

  // Render list. Update files to upload. Update upload button
  selectedFilesDefaultActions() {
    this.renderFileList();
    this.updateFileInput();
    this.updateFileUploadButton();
  }

  // Render files selected to upload
  renderFileList() {
    this.fileListTarget.innerHTML = "";

    this.files.forEach((file, index) => {
      const fileItem = document.createElement("div");
      fileItem.classList.add("selected-file-item");

      const removeButton = document.createElement("i");
      removeButton.classList.add("bi", "bi-x", "mx-2", "remove-file-button");
      removeButton.dataset.action = "click->drag-and-drop#removeFile";
      removeButton.dataset.index = index;

      const fileName = document.createElement("i");
      fileName.textContent =
        file.name + " - " + (file.size / (1024 * 1024)).toFixed(3) + " Mb's";

      fileItem.appendChild(removeButton);
      fileItem.appendChild(fileName);
      this.fileListTarget.appendChild(fileItem);
    });
  }

  // Remove selected file
  removeFile(event) {
    const fileIndex = event.currentTarget.dataset.index;
    this.files.splice(fileIndex, 1);
    this.selectedFilesDefaultActions();
  }

  // Update files selection to upload
  updateFileInput(files) {
    const dataTransfer = new DataTransfer();
    this.files.forEach((file) => dataTransfer.items.add(file));
    this.fileInputTarget.files = dataTransfer.files;
  }

  // Update enabled/disabled from upload button
  updateFileUploadButton() {
    this.fileUploadButtonTarget.disabled = this.files.length === 0;
  }

  // Upload files with button
  uploadFiles() {
    this.files.forEach((file) => {
      const upload = new DirectUpload(
        file,
        this.fileInputTarget.dataset.directUploadUrl,
      );
      upload.create((error, blob) => {
        if (error) {
          console.error("Upload failed: " + error);
        } else {
          this.appendHiddenInput(blob);
        }
      });
    });
  }

  // Hidden input for file signed_id
  appendHiddenInput(blob) {
    const hiddenField = document.createElement("input");
    hiddenField.setAttribute("type", "hidden");
    hiddenField.setAttribute("value", blob.signed_id);
    hiddenField.setAttribute("name", blob.filename);
    this.element.appendChild(hiddenField);
  }
}
