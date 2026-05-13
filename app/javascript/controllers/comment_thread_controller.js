import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "zp_character_id"

export default class extends Controller {
  static targets = ["characterSelect"]

  connect() {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (stored && this.hasCharacterSelectTarget) {
      this.characterSelectTarget.value = stored
    }
    this.personalize()
    this.observer = new MutationObserver(() => this.personalize())
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  storeCharacter(event) {
    localStorage.setItem(STORAGE_KEY, event.target.value)
    this.personalize()
  }

  personalize() {
    const id = localStorage.getItem(STORAGE_KEY)
    if (!id) return
    this.element.querySelectorAll("[data-character-id]").forEach(bubble => {
      bubble.classList.toggle("bubble--mine", bubble.dataset.characterId === id)
    })
  }
}
