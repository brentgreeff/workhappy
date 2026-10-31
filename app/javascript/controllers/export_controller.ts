import { Controller } from "@hotwired/stimulus"

type ExportState = {
  status: "queued" | "processing" | "ready" | "failed"
  row_count: number | null
  error: string | null
  poll_url: string
  download_url: string | null
}

const POLL_MS = 2000

// Submits the export form over fetch, then polls the export until it is ready or failed.
// The button carries the state; the status span carries the detail.
export default class ExportController extends Controller<HTMLFormElement> {
  static targets = ["button", "status", "link", "from", "to"]

  declare readonly buttonTarget: HTMLButtonElement
  declare readonly statusTarget: HTMLElement
  declare readonly linkTarget: HTMLAnchorElement
  declare readonly fromTarget: HTMLInputElement
  declare readonly toTarget: HTMLInputElement

  private timer?: number

  disconnect(): void {
    window.clearTimeout(this.timer)
  }

  // The earliest and latest dates the company has, rendered on the button by the server.
  allTime({ params: { from, to } }: { params: { from: string; to: string } }): void {
    this.fromTarget.value = from
    this.toTarget.value = to
  }

  async submit(event: Event): Promise<void> {
    event.preventDefault()
    window.clearTimeout(this.timer)
    this.begin()

    try {
      const response = await fetch(this.element.action, {
        method: "POST",
        credentials: "same-origin",
        headers: { Accept: "application/json", "X-CSRF-Token": this.csrfToken() },
        body: new FormData(this.element)
      })
      const data = await response.json()
      if (!response.ok) throw new Error(data.error ?? "Export could not be started")
      this.apply(data as ExportState)
    } catch (error) {
      this.fail(error instanceof Error ? error.message : String(error))
    }
  }

  private begin(): void {
    this.buttonTarget.disabled = true
    this.linkTarget.hidden = true
    this.statusTarget.textContent = "Queued"
  }

  private apply(data: ExportState): void {
    switch (data.status) {
      case "ready":
        this.statusTarget.textContent = `Ready: ${data.row_count ?? 0} rows`
        if (data.download_url) {
          this.linkTarget.href = data.download_url
          this.linkTarget.hidden = false
        }
        this.buttonTarget.disabled = false
        break
      case "failed":
        this.fail(data.error ?? "Export failed")
        break
      default:
        this.statusTarget.textContent = data.status === "processing" ? "Processing" : "Queued"
        this.timer = window.setTimeout(() => void this.poll(data.poll_url), POLL_MS)
    }
  }

  private async poll(url: string): Promise<void> {
    try {
      const response = await fetch(url, { credentials: "same-origin", headers: { Accept: "application/json" }, cache: "no-store" })
      if (!response.ok) throw new Error("Export is no longer available, reload the page")
      this.apply((await response.json()) as ExportState)
    } catch (error) {
      this.fail(error instanceof Error ? error.message : String(error))
    }
  }

  private fail(message: string): void {
    this.statusTarget.textContent = message
    this.buttonTarget.disabled = false
  }

  private csrfToken(): string {
    return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? ""
  }
}
