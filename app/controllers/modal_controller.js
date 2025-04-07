// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.modal = document.getElementById('review-modal')
    this.openButton = document.querySelector('[data-modal-target="review-modal"]')
    this.closeButton = document.querySelector('[data-modal-close]')
    
    if (this.openButton) {
      this.openButton.addEventListener('click', () => this.open())
    }
    
    if (this.closeButton) {
      this.closeButton.addEventListener('click', () => this.close())
    }
  }

  open() {
    this.modal.classList.remove('hidden')
  }

  close() {
    this.modal.classList.add('hidden')
  }
}