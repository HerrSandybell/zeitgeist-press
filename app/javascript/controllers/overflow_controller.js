import { Controller } from "@hotwired/stimulus"

// Detects whether a story's body has more content than fits in its allotted
// space. Reveals the "Continued" link and tags the article with
// .story--overflows (which triggers the fade gradient in CSS).
//
// Single-column bodies overflow vertically: scrollHeight > clientHeight.
// Multi-column bodies (with column-fill: auto) overflow horizontally as
// excess content spills into additional columns beyond the visible ones:
// scrollWidth > clientWidth.
//
// We measure .story-body (not the article) because flexbox constrains it to
// the available height, so the measurement is accurate. document.fonts.ready
// + rAF ensures fonts have loaded and the browser has run a layout pass.
export default class extends Controller {
  static targets = ["link"]

  connect() {
    document.fonts.ready.then(() => requestAnimationFrame(() => this.detectOverflow()))
  }

  detectOverflow() {
    const body = this.element.querySelector(".story-body")
    if (!body) return

    const overflowsVertically = body.scrollHeight > body.clientHeight
    const overflowsHorizontally = body.scrollWidth > body.clientWidth

    if (overflowsVertically || overflowsHorizontally) {
      if (this.hasLinkTarget) {
        this.linkTarget.hidden = false
      }
      this.element.classList.add("story--overflows")
    }
  }
}
