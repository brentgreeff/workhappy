import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import ThemeController from "./controllers/theme_controller"
import ExportController from "./controllers/export_controller"

const application = Application.start()
application.register("theme", ThemeController)
application.register("export", ExportController)

export { application }
