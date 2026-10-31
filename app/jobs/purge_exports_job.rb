# Exports are a convenience copy of health data; they do not live long. Scheduled hourly in
# config/recurring.yml.
class PurgeExportsJob < ApplicationJob
  queue_as :default

  def perform(older_than: 24.hours)
    Export.where(created_at: ...older_than.ago).find_each(&:destroy!)
  end
end
