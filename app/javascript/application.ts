import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import DateRangeController from "./controllers/date_range_controller"
import ExportController from "./controllers/export_controller"

const application = Application.start()
application.register("date-range", DateRangeController)
application.register("export", ExportController)

export { application }
