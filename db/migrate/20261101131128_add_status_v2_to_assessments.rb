# The new status column beside the legacy one. Nullable, because legacy rows stay NULL until the
# backfill runs. The CHECK is NOT VALID: no scan of existing rows, enforced on every write from
# here on. The values are written out so the migration never depends on app code.
class AddStatusV2ToAssessments < ActiveRecord::Migration[8.1]
  ALLOWED = %w[pending in_progress completed needs_follow_up archived].freeze

  def up
    with_lock_timeout do
      add_column :assessments, :status_v2, :string
      add_check_constraint(:assessments,
        "status_v2 IN (#{ALLOWED.map { |value| "'#{value}'" }.join(', ')})",
        name: "assessments_status_v2_allowed", validate: false
      )
    end
  end

  def down
    with_lock_timeout do
      remove_check_constraint :assessments, name: "assessments_status_v2_allowed"
      remove_column :assessments, :status_v2
    end
  end

  private

  # Both statements take a brief exclusive lock. Waiting behind a long transaction would queue
  # every other query on the table, so give up after 2s and fail the release instead.
  def with_lock_timeout
    execute "SET LOCAL lock_timeout = '2s'"
    yield
  end
end
