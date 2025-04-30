import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Listen for marker-clicked event
    this.element.addEventListener('marker-clicked', this.highlight.bind(this))
  }
  
  disconnect() {
    // Clean up event listener
    this.element.removeEventListener('marker-clicked', this.highlight.bind(this))
  }
  
  highlight() {
    // Add highlight class
    this.element.classList.add('bg-[#355E3B]/10')
    
    // Remove highlight after 2 seconds
    setTimeout(() => {
      this.element.classList.remove('bg-[#355E3B]/10')
    }, 2000)
  }
} 