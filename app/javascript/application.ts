import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import ThemeController from "./controllers/theme_controller"

const application = Application.start()
application.register("theme", ThemeController)

export { application }
