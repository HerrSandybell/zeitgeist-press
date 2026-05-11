import { Controller } from "@hotwired/stimulus"

// Owns the dimmed backdrop and the Turbo Frame that holds the cutout.
// Lifecycle:
//   - turbo:frame-load@window  -> #show (backdrop fades in, ESC listener attached)
//   - click on .overlay-frame  -> #close (the backdrop itself)
//   - click on the frame       -> #stopPropagation (clicking the cutout doesn't dismiss)
//   - keydown ESC anywhere     -> #close (registered globally while open)
//
// On close, we clear the frame's innerHTML so Turbo refetches the next
// time the same story is reopened. Without this, Turbo's frame cache
// would skip the request and the frame-load event would never fire.
export default class extends Controller {
  static targets = ["frame"]

  connect() {
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  show() {
    this.element.classList.add("overlay-frame--open")
    document.addEventListener("keydown", this.closeOnEscape)
  }

  close() {
    this.element.classList.remove("overlay-frame--open")
    if (this.hasFrameTarget) {
      this.frameTarget.innerHTML = ""
    }
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
