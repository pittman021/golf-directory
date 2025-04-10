import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["region", "state"]

  connect() {
    if (this.hasRegionTarget && this.hasStateTarget) {
      this.updateStates()
    }
  }

  async updateStates() {
    const region = this.regionTarget.value
    const response = await fetch(`/locations/states_for_region?region=${encodeURIComponent(region)}`)
    const states = await response.json()
    
    // Clear existing options except the first one (if it's a placeholder)
    const firstOption = this.stateTarget.options[0]
    this.stateTarget.innerHTML = ''
    if (firstOption && firstOption.value === '') {
      this.stateTarget.appendChild(firstOption)
    }

    // Add new state options
    states.forEach(state => {
      const option = new Option(state, state)
      this.stateTarget.add(option)
    })

    // Enable the state select
    this.stateTarget.disabled = states.length === 0
  }
} 