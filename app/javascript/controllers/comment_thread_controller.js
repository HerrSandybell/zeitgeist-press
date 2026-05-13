import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "zp_character_id"

export default class extends Controller {
  static targets = ["characterSelect"]

  connect() {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (stored && this.hasCharacterSelectTarget) {
      this.characterSelectTarget.value = stored
    }
  }

  storeCharacter(event) {
    localStorage.setItem(STORAGE_KEY, event.target.value)
  }
}
