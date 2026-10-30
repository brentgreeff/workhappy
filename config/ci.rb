CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"
  step "Types: TypeScript", "npm run typecheck"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: npm audit", "npm audit --audit-level=high"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Tests: RSpec", "bin/rspec"
end
