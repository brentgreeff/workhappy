class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
  # The tenant. Every assessment query starts here; no action reads a company id from params.
  # No allow_nil: asking for the tenant with nobody signed in is a bug and should raise, not
  # turn a scope into `company_id IS NULL`.
  delegate :company, to: :user
end
