# Quento Code Style Guide

We aim to write code that is a pleasure to read. Writing great code is an essential part of our programming culture, and we deliberately set a high bar for every code change.

When writing new code, unless you are very familiar with our approach, try to find similar code elsewhere to look for inspiration. A Pull Request is a great way to discuss code patterns.

**Key Principle:** Code should be optimized for reading, not writing. We spend far more time reading code than writing it.

---

## Model Organization

### Concern-Based Composition

**When a model exceeds 200 lines, extract concerns by responsibility:**

```ruby
# ❌ Bad - 500+ line monolithic model
class Invoice < ApplicationRecord
  # All associations, validations, callbacks, methods mixed together
  # Hard to navigate and understand
end

# ✅ Good - Composed from focused concerns
class Invoice < ApplicationRecord
  include Invoice::Associations      # belongs_to, has_many
  include Invoice::Validations       # validates, validate
  include Invoice::Scopes           # scopes with preloading
  include Invoice::NumberGeneration  # invoice_number logic
  include Invoice::Calculations      # totals, tax, discount
  include Invoice::Snapshotting      # buyer/seller snapshots
  include Invoice::PaymentTracking   # amount_paid, fully_paid?
  include Invoice::StateMachine      # AASM transitions
  include Invoice::PdfRendering      # PDF-related methods
  
  # Only core configuration here
  monetize :total_cents, with_model_currency: :currency
  accepts_nested_attributes_for :invoice_items
end
```

**Concern naming and structure:**

```ruby
# app/models/invoice/calculations.rb
module Invoice::Calculations
  extend ActiveSupport::Concern
  
  included do
    before_save :calculate_totals
  end
  
  # Public interface
  def calculate_totals
    calculate_subtotal
    calculate_discount
    calculate_tax
    calculate_total
  end
  
  def vat_breakdown
    # ...
  end
  
  # Implementation details
  private
    def calculate_subtotal
      # ...
    end
    
    def calculate_discount
      # ...
    end
    
    def calculate_tax
      calculate_tax_with_discount(items, subtotal_cents, discount_amount_cents)
    end
    
    def calculate_tax_with_discount(items, subtotal_value, discount_value)
      # Complex logic isolated here
    end
    
    def calculate_total
      # ...
    end
end
```

---

## Method Ordering

### Order by Invocation Flow

**Methods should be ordered vertically by their call chain. This helps readers follow the logic top-to-bottom:**

```ruby
class InvoiceNumberGenerator
  # 1. Public entry point at top
  def generate
    validate_company
    determine_pattern
    find_sequence
    format_number
  end

  # 2. Private methods follow in order of invocation
  private
    def validate_company
      raise "No company" unless company.present?
    end
  
    def determine_pattern
      @pattern = company.invoice_number_pattern || default_pattern
    end
    
    def default_pattern
      "{num}/{month}/{year}"
    end
  
    def find_sequence
      find_max_sequence
      increment_sequence
    end
    
    def find_max_sequence
      # ...
    end
    
    def increment_sequence
      # ...
    end
  
    def format_number
      @pattern
        .gsub("{num}", format_sequence)
        .gsub("{month}", format_month)
        .gsub("{year}", format_year)
    end
    
    def format_sequence
      format("%03d", @sequence)
    end
    
    def format_month
      # ...
    end
    
    def format_year
      # ...
    end
end
```

**Why this matters:** Readers can follow the logic flow without jumping around the file.

---

## Visibility Modifiers

### No Blank Line After `private`, Indent Methods

```ruby
# ✅ Good
class SomeClass
  def public_method
    # ...
  end

  private
    def private_method_1
      # ...
    end

    def private_method_2
      # ...
    end
end
```

```ruby
# ❌ Bad - extra blank line and no indentation
class SomeClass
  def public_method
    # ...
  end

  private
  
  def private_method_1
    # ...
  end
end
```

**Exception: Module with ONLY private methods:**

```ruby
module SomeHelper
  private
  
  def helper_method_1
    # No indentation when entire module is private
  end
  
  def helper_method_2
    # ...
  end
end
```

---

## Bang Methods (!)

### Use `!` for Methods That Raise, Not for Destructive Actions

We follow Rails conventions: `!` means "raises an exception on failure."

```ruby
# ✅ Good - ! raises on validation failure
invoice.update!(status: "paid")
invoice.save!
invoice.issue!  # State transition that persists

# ✅ Good - no ! for destructive actions without non-bang counterpart
invoice.archive   # No archive! unless there's also an archive method
invoice.delete_items
```

**Rule:** Only use `!` when there's a non-bang counterpart or when following Rails conventions (save/save!, create/create!, update/update!).

---

## Controllers

### Thin Controllers, Rich Models

Controllers should delegate business logic to models. No service layer.

```ruby
# ❌ Bad - business logic in controller
class InvoicesController < ApplicationController
  def mark_as_paid
    @invoice.aasm_state = "paid"
    @invoice.paid_at = Time.current
    @invoice.save!
    
    # Cancel all pending reminders
    @invoice.payment_reminders.pending.each do |reminder|
      reminder.cancel!
    end
    
    redirect_to @invoice
  end
end

# ✅ Good - delegate to rich model API
class InvoicesController < ApplicationController
  def mark_as_paid
    @invoice.mark_paid!
    redirect_to @invoice, notice: t("invoices.marked_as_paid")
  end
end

# app/models/invoice.rb
class Invoice < ApplicationRecord
  def mark_paid!
    transaction do
      update!(aasm_state: "paid", paid_at: Time.current)
      cancel_payment_reminders
    end
  end
  
  private
    def cancel_payment_reminders
      payment_reminders.pending.each(&:cancel!)
    end
end
```

### Resource-Oriented Routes

Model actions as resources, not custom verbs.

```ruby
# ❌ Bad - custom actions
resources :invoices do
  member do
    patch :issue
    patch :mark_as_paid
    patch :cancel
    post :send_email
    post :send_reminder
  end
end

# ✅ Good - resources for actions
resources :invoices do
  resource :issuance, only: [:create]
  resource :payment, only: [:create]
  resource :cancellation, only: [:create]
  resource :email_delivery, only: [:create]
  resource :reminder, only: [:create]
end

# Separate controllers
class Invoices::IssuancesController < ApplicationController
  def create
    @invoice.issue!
    redirect_to @invoice, notice: t("invoices.issued")
  end
end

class Invoices::PaymentsController < ApplicationController
  def create
    @invoice.mark_paid!
    redirect_to @invoice, notice: t("invoices.marked_as_paid")
  end
end
```

**Benefits:**
- RESTful consistency
- Easier to test in isolation
- Clear separation of concerns
- Better URL structure: `POST /invoices/123/issuance`

---

## Background Jobs

### Use _later/_now Pattern, Keep Jobs Thin

Jobs should be thin wrappers that delegate to models.

```ruby
# ❌ Bad - business logic in job
class KsefSubmissionJob < ApplicationJob
  def perform(submission_id)
    submission = KsefSubmission.find(submission_id)
    
    # 300 lines of business logic here
    fa3_xml = generate_fa3_xml(submission.invoice)
    encrypted = encrypt_xml(fa3_xml)
    # ...
  end
  
  private
    def generate_fa3_xml(invoice)
      # Complex logic
    end
end

# ✅ Good - thin job, rich model
class KsefSubmissionJob < ApplicationJob
  def perform(submission_id)
    submission = KsefSubmission.find(submission_id)
    Current.account = submission.account
    
    submission.submit_now
  ensure
    Current.account = nil
  end
end

# app/models/ksef_submission.rb
class KsefSubmission < ApplicationRecord
  # Public interface
  def submit_later
    KsefSubmissionJob.perform_later(id)
  end
  
  def submit_now
    generate_fa3_xml
    encrypt_xml
    authenticate
    submit_to_ksef
  end
  
  private
    def generate_fa3_xml
      # Business logic in model
    end
    
    def encrypt_xml
      # ...
    end
end
```

**Benefits:**
- Business logic stays in domain models
- Easier to test (no job overhead)
- Can call `submit_now` synchronously in tests
- Job only handles infrastructure (Current.account, error handling)

---

## Scopes and Queries

### Provide Preloaded Scopes for Common Views

Always create scopes that preload associations to avoid N+1 queries.

```ruby
class Invoice < ApplicationRecord
  # ❌ Bad - no preloading helpers
  scope :recent, -> { order(created_at: :desc) }
  
  # Controller has to remember what to include
  @invoices = Invoice.recent.includes(:client, :company, invoice_items: :product)
end

# ✅ Good - preloaded scopes
class Invoice < ApplicationRecord
  # Individual preloading scopes
  scope :with_associations, -> { includes(:client, :company, :bank_account) }
  scope :with_items, -> { includes(invoice_items: :product) }
  scope :with_payments, -> { includes(:payments) }
  scope :with_reminders, -> { includes(:payment_reminders) }
  
  # Composed scopes for specific views
  scope :preloaded_for_list, -> {
    with_associations
      .with_items
      .order(issue_date: :desc)
  }
  
  scope :preloaded_for_show, -> {
    with_associations
      .with_items
      .with_payments
      .with_reminders
      .includes(:ksef_submissions)
  }
  
  scope :preloaded_for_pdf, -> {
    with_associations
      .with_items
  }
end

# Controller is clean and declarative
class InvoicesController < ApplicationController
  def index
    @invoices = current_account.invoices.preloaded_for_list.page(params[:page])
  end
  
  def show
    @invoice = current_account.invoices.preloaded_for_show.find(params[:id])
  end
end
```

---

## Testing Patterns

### Always Test Multi-Tenancy Isolation

Every scoped model must have a cross-account isolation test.

```ruby
class InvoiceTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(name: "Test", subdomain: "test", plan: "free", status: "active")
    Current.account = @account
    @company = @account.companies.create!(name: "Test Co", tax_id: "123")
    @client = @account.clients.create!(name: "Test Client")
  end
  
  teardown do
    Current.account = nil
  end
  
  test "cross-account isolation - cannot access other account's invoices" do
    other_account = Account.create!(name: "Other", subdomain: "other", plan: "free", status: "active")
    Current.account = other_account
    other_company = other_account.companies.create!(name: "Other Co", tax_id: "456")
    other_client = other_account.clients.create!(name: "Other Client")
    other_invoice = other_account.invoices.create!(company: other_company, client: other_client)
    
    Current.account = @account
    
    # Should not find invoice from other account
    assert_nil Invoice.find_by(id: other_invoice.id)
    assert_equal 0, Invoice.count
  end
  
  test "cross-account validation - client must belong to same account" do
    other_account = Account.create!(name: "Other", subdomain: "other", plan: "free", status: "active")
    other_client = other_account.clients.create!(name: "Other Client")
    
    invoice = Invoice.new(account: @account, company: @company, client: other_client)
    assert_not invoice.valid?
    assert_includes invoice.errors[:client], "must belong to the same account"
  end
end
```

---

## Error Handling

### Controllers: rescue_from, Models: raise specific exceptions

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from Invoice::KsefError, with: :handle_ksef_error
  
  private
    def handle_not_found
      render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
    end
    
    def handle_ksef_error(exception)
      redirect_to invoices_path, alert: t("ksef.errors.#{exception.code}")
    end
end

# app/models/invoice.rb
class Invoice < ApplicationRecord
  class KsefError < StandardError
    attr_reader :code
    
    def initialize(message, code:)
      super(message)
      @code = code
    end
  end
  
  def submit_to_ksef
    raise KsefError.new("Not configured", code: :not_configured) unless ksef_configured?
    # ...
  end
end
```

---

## I18n

### Never Hardcode Text, Always Use Helpers

```ruby
# ❌ Bad
flash[:notice] = "Invoice has been issued"
<h1>Invoices</h1>

# ✅ Good
flash[:notice] = t("invoices.issued")
<h1><%= t("invoices.index.title") %></h1>
```

**Always update all three locale files:**

```yaml
# config/locales/en.yml
en:
  invoices:
    issued: "Invoice has been issued"
    index:
      title: "Invoices"

# config/locales/pl.yml
pl:
  invoices:
    issued: "Faktura została wystawiona"
    index:
      title: "Faktury"

# config/locales/de.yml
de:
  invoices:
    issued: "Rechnung wurde ausgestellt"
    index:
      title: "Rechnungen"
```

---

## Performance

### Avoid N+1 Queries with Preloading

```ruby
# ❌ Bad - N+1 query
@invoices = Invoice.all
@invoices.each do |invoice|
  puts invoice.client.name      # Query for each invoice
  puts invoice.company.name     # Query for each invoice
  invoice.invoice_items.each do |item|
    puts item.product.name      # Query for each item
  end
end

# ✅ Good - single query with preloading
@invoices = Invoice.preloaded_for_list.all
@invoices.each do |invoice|
  puts invoice.client.name      # No query
  puts invoice.company.name     # No query
  invoice.invoice_items.each do |item|
    puts item.product.name      # No query
  end
end
```

### Use Database Calculations, Not Ruby

```ruby
# ❌ Bad - loads all records into memory
total = Invoice.all.sum { |i| i.total_cents }
count = Invoice.all.select { |i| i.paid? }.count

# ✅ Good - database does the work
total = Invoice.sum(:total_cents)
count = Invoice.paid.count
```

---

## Before Submitting Code

**Run through this checklist:**

- [ ] Model < 200 lines? If not, extract concerns
- [ ] Methods ordered by invocation flow?
- [ ] Private methods indented under `private` without blank line?
- [ ] Cross-account isolation tested?
- [ ] Preloading scopes used to avoid N+1 queries?
- [ ] Background jobs use `_later`/`_now` pattern?
- [ ] I18n keys added to all three locales (en, pl, de)?
- [ ] Routes follow resource-oriented design?
- [ ] No hardcoded strings in views/controllers?
- [ ] `bin/ci` passes?

---

## Learning Resources

- **Find similar code:** Look for existing patterns in the codebase before writing new code
- **Pull Requests:** Great place to discuss code patterns and get feedback
- **AGENTS.md:** Quick reference guide for AI agents and developers
- **README.md:** Project overview and development setup
