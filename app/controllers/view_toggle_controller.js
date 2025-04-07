// app/javascript/controllers/view_toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table", "map"]

  connect() {
    document.querySelectorAll('[data-view]').forEach(button => {
      button.addEventListener('click', (e) => this.toggleView(e))
    })
  }

  toggleView(event) {
    const view = event.currentTarget.dataset.view
    const tableView = document.getElementById('table-view')
    const mapView = document.getElementById('map-view')
    
    // Toggle views
    if (view === 'map') {
      tableView.classList.add('hidden')
      mapView.classList.remove('hidden')
    } else {
      mapView.classList.add('hidden')
      tableView.classList.remove('hidden')
    }
    
    // Toggle active state on buttons
    document.querySelectorAll('[data-view]').forEach(button => {
      button.classList.remove('active')
    })
    event.currentTarget.classList.add('active')
  }
}