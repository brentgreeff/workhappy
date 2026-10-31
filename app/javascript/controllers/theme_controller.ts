import { Controller } from "@hotwired/stimulus"

type Choice = "light" | "dark" | "system"

const media = window.matchMedia("(prefers-color-scheme: dark)")

// Three-way theme menu. "system" clears the stored choice and follows the OS; the other
// two persist in localStorage. layouts/_head applies the same rule before first paint so
// the page never flashes the wrong theme.
export default class ThemeController extends Controller {
  static targets = ["choice"]

  declare readonly choiceTargets: HTMLButtonElement[]

  connect(): void {
    media.addEventListener("change", this.apply)
    window.addEventListener("storage", this.apply)
    this.apply()
  }

  disconnect(): void {
    media.removeEventListener("change", this.apply)
    window.removeEventListener("storage", this.apply)
  }

  select({ params: { choice } }: { params: { choice: Choice } }): void {
    if (choice === "system") {
      localStorage.removeItem("theme")
    } else {
      localStorage.setItem("theme", choice)
    }
    this.apply()
  }

  apply = (): void => {
    const stored = localStorage.getItem("theme")
    const dark = stored === "dark" || (!stored && media.matches)
    document.documentElement.classList.toggle("dark", dark)

    const active = stored ?? "system"
    this.choiceTargets.forEach(target => {
      target.setAttribute("aria-checked", String(target.dataset.themeChoiceParam === active))
    })
  }
}
