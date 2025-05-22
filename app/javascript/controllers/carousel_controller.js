import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "prevButton", "nextButton"]

  connect() {
    this.currentIndex = 0
    this.updateNavigation()
  }

  next() {
    if (this.canMoveNext()) {
      this.currentIndex++
      this.updatePosition()
      this.updateNavigation()
    }
  }

  previous() {
    if (this.canMovePrevious()) {
      this.currentIndex--
      this.updatePosition()
      this.updateNavigation()
    }
  }

  updatePosition() {
    const itemWidth = this.containerTarget.firstElementChild?.offsetWidth || 0
    const translateX = -(this.currentIndex * itemWidth)
    this.containerTarget.style.transform = `translateX(${translateX}px)`
  }

  updateNavigation() {
    this.prevButtonTarget.disabled = !this.canMovePrevious()
    this.nextButtonTarget.disabled = !this.canMoveNext()
  }

  canMoveNext() {
    const containerWidth = this.containerTarget.offsetWidth
    const scrollWidth = this.containerTarget.scrollWidth
    const currentPosition = this.currentIndex * (this.containerTarget.firstElementChild?.offsetWidth || 0)
    return currentPosition + containerWidth < scrollWidth
  }

  canMovePrevious() {
    return this.currentIndex > 0
  }
} 