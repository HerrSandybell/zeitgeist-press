import { Controller } from "@hotwired/stimulus"

// Detects whether a story article's content exceeds its grid cell.
// If so: reveals the "Continued" link and tags the article with
// .story--overflows (which triggers the fade gradient in CSS).
//
// We measure this.element (the <article>) because the grid pins it to
// var(--grid-row-unit) and clips with overflow: hidden. The story-body
// itself has no fixed height — measuring it would always return 0 overflow.
//
// document.fonts.ready is essential: web fonts load asynchronously, and
// measuring before they arrive produces false negatives based on fallback
// font metrics.
export default class extends Controller {
  static targets = ["link"]

  connect() {
    document.fonts.ready.then(() => this.detectOverflow())
  }

  detectOverflow() {
    if (this.element.scrollHeight > this.element.clientHeight) {
      if (this.hasLinkTarget) {
        this.linkTarget.hidden = false
      }
      this.element.classList.add("story--overflows")
    }
  }
}
