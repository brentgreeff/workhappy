# Task 3, expand phase. A new nullable column that can only hold the five allowed values, beside
# the legacy free-text status, which is never modified. The CHECK is NOT VALID: no scan of the
# existing rows (all NULL anyway), enforced on every insert and update from this moment.
# Validated later, before NOT NULL, once the backfill has run.
#
# The five values are written out rather than read from AssessmentStatus so the migration stays
# self-contained; a spec asserts the two lists are the same.
class AddStatusV2ToAssessments < ActiveRecord::Migration[8.1]
  # One statement per lock attempt: a lock timeout then aborts that statement, not a transaction
  # we would have to restart from the top.
  disable_ddl_transaction!

  ALLOWED = %w[pending in_progress completed needs_follow_up archived].freeze

  def up
    with_lock_budget { add_column :assessments, :status_v2, :string }
    with_lock_budget do
      add_check_constraint :assessments,
        "status_v2 IS NULL OR status_v2 IN (#{ALLOWED.map { |value| "'#{value}'" }.join(', ')})",
        name: "assessments_status_v2_allowed", validate: false
    end
  end

  def down
    remove_check_constraint :assessments, name: "assessments_status_v2_allowed"
    remove_column :assessments, :status_v2
  end

  private

  # ADD COLUMN and ADD CONSTRAINT take a brief ACCESS EXCLUSIVE lock. The risk is not the work,
  # it is waiting for the lock behind a long transaction while every other statement queues
  # behind us. A short lock_timeout bounds that wait; a few retries ride out a transient
  # blocker; after that the release fails, which is the right outcome.
  def with_lock_budget(attempts: 5)
    execute "SET lock_timeout = '2s'"
    yield
  rescue ActiveRecord::LockWaitTimeout
    attempts -= 1
    raise if attempts.zero?

    say "lock not acquired within 2s, retrying (#{attempts} left)"
    sleep 2
    retry
  ensure
    execute "RESET lock_timeout"
  end
end
