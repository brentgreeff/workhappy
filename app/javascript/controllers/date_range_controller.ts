import { Controller } from "@hotwired/stimulus"

// "All time" fills the two date inputs with the span the server rendered on the button.
export default class DateRangeController extends Controller {
  static targets = ["from", "to"]

  declare readonly fromTarget: HTMLInputElement
  declare readonly toTarget: HTMLInputElement

  allTime({ params: { from, to } }: { params: { from: string; to: string } }): void {
    this.fromTarget.value = from
    this.toTarget.value = to
  }
}
