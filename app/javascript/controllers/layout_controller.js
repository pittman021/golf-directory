import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["gridView", "listView", "gridButton", "listButton"]

  connect() {
    // Check if there's a saved preference
    const savedLayout = localStorage.getItem('preferredLayout')
    if (savedLayout === 'list') {
      this.showList()
    } else {
      // Default to grid
      this.showGrid()
    }
    
    // Hide the toggle on mobile devices
    this.updateToggleVisibility()
    window.addEventListener('resize', this.updateToggleVisibility.bind(this))
  }
  
  disconnect() {
    window.removeEventListener('resize', this.updateToggleVisibility.bind(this))
  }
  
  showGrid() {
    this.gridViewTarget.classList.remove('hidden')
    this.listViewTarget.classList.add('hidden')
    this.gridButtonTarget.classList.add('bg-indigo-600', 'text-white')
    this.gridButtonTarget.classList.remove('bg-white', 'text-gray-500')
    this.listButtonTarget.classList.add('bg-white', 'text-gray-500')
    this.listButtonTarget.classList.remove('bg-indigo-600', 'text-white')
    localStorage.setItem('preferredLayout', 'grid')
  }
  
  showList() {
    this.gridViewTarget.classList.add('hidden')
    this.listViewTarget.classList.remove('hidden')
    this.listButtonTarget.classList.add('bg-indigo-600', 'text-white')
    this.listButtonTarget.classList.remove('bg-white', 'text-gray-500')
    this.gridButtonTarget.classList.add('bg-white', 'text-gray-500')
    this.gridButtonTarget.classList.remove('bg-indigo-600', 'text-white')
    localStorage.setItem('preferredLayout', 'list')
  }
  
  updateToggleVisibility() {
    const toggleElement = this.element.querySelector('.layout-toggle')
    if (toggleElement) {
      if (window.innerWidth < 640) { // sm breakpoint in Tailwind
        toggleElement.classList.add('hidden')
      } else {
        toggleElement.classList.remove('hidden')
      }
    }
  }
} 