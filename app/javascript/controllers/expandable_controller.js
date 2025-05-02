import { Controller } from "@hotwired/stimulus"

/**
 * Expandable text controller
 * Used to show/hide content with a "Read More"/"Show Less" toggle
 *
 * Usage:
 * <div data-controller="expandable">
 *   <div data-expandable-target="teaser" class="line-clamp-4">
 *     <!-- Teaser content -->
 *   </div>
 *   <div data-expandable-target="full" class="hidden">
 *     <!-- Full content -->
 *   </div>
 *   <button data-action="expandable#toggle" data-expandable-target="button">Read More</button>
 * </div>
 */
export default class extends Controller {
  static targets = ["teaser", "full", "button"]
  
  connect() {
    // If content is short enough, hide the button
    if (this.fullTarget.textContent.trim().length <= this.teaserTarget.textContent.trim().length) {
      this.buttonTarget.classList.add('hidden');
    }
  }
  
  toggle(event) {
    event.preventDefault();
    
    if (this.teaserTarget.classList.contains('hidden')) {
      // Show teaser, hide full content
      this.teaserTarget.classList.remove('hidden');
      this.fullTarget.classList.add('hidden');
      this.buttonTarget.textContent = 'Read More';
    } else {
      // Hide teaser, show full content
      this.teaserTarget.classList.add('hidden');
      this.fullTarget.classList.remove('hidden');
      this.buttonTarget.textContent = 'Show Less';
    }
  }
} 