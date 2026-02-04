# Accounting Feature Agent

Domain-specific agent for reviewing and implementing accounting/financial features.

---

## When to Use

- **Manually:** `/accounting-review`
- **Auto-trigger:** PRs touching `backend/apps/accounting/`, `invoices/`, `payments/`, `billing/`

---

## On Invocation: Check for Updates

Before applying rules, check if the source document has been updated:

```
1. Call: mcp__linear-server__get_document(id: "b05fc81b-b20d-41f2-9ffb-f4ceb62879c5")
2. Check the "updatedAt" field
3. Compare to LAST_SYNCED below
4. If Linear doc is newer:
   → Alert: "⚠️ Accounting rules were updated on [date]. Review changes at:
     https://linear.app/crispa/document/accounting-rules-dos-and-donts-f470a2e9fbdb
     Then update this agent or run /refresh-accounting-rules"
5. Continue with embedded rules below
```

**LAST_SYNCED:** 2026-02-04T14:58:41.837Z

---

## Accounting Rules

> **Source:** [Linear - Accounting Rules](https://linear.app/crispa/document/accounting-rules-dos-and-donts-f470a2e9fbdb)
> **Notion Mirror:** [Dos and Don'ts](https://www.notion.so/Dos-and-Donts-Linear-Sync-2fd608f8081480758ab1da31b39f97e8)
> **Owner:** Oliver (Product)

---

### ✅ DOs

#### Data Handling
- Always use `Decimal` for monetary values, never `float`
- Always include currency code with amounts
- Always use tenant's locale settings for formatting
- Always wrap financial mutations in `@transaction.atomic`

#### Audit & Compliance
- Always create audit trail entries for financial changes
- Always log who made changes and when
- Always validate against double-entry accounting principles

#### Multi-tenancy
- Always filter queries by tenant
- Always verify tenant ownership before mutations

---

### ❌ DON'Ts

#### Hardcoding
- Never hardcode `da-DK` locale
- Never hardcode `DKK` or any currency
- Never hardcode tax rates
- Never hardcode account numbers

#### Data Integrity
- Never delete financial records - soft delete only
- Never modify closed periods without reopening
- Never allow negative inventory (unless configured)

#### Security
- Never expose full account numbers in APIs
- Never log sensitive financial data

---

### Invoice-Specific Rules

#### Month Close
- Prevent modifications to invoices in closed periods
- Require explicit "reopen period" action with audit log
- Validate invoice date against open periods

---

## Code Examples

### Good
```python
from decimal import Decimal
from django.db import transaction

@transaction.atomic
def create_invoice(tenant, data, user):
    amount = Decimal(str(data["amount"]))
    currency = tenant.default_currency

    invoice = Invoice.objects.create(
        tenant=tenant,
        amount=amount,
        currency=currency,
        created_by=user
    )

    AuditLog.objects.create(
        tenant=tenant,
        action="invoice_created",
        entity_id=invoice.id,
        user=user
    )
    return invoice
```

### Bad
```python
def create_invoice(data):
    amount = 100.0              # float - precision loss
    currency = "DKK"            # hardcoded
    Invoice.objects.create(     # no tenant filter
        amount=amount,          # no audit trail
        currency=currency       # no transaction
    )
```

---

## Review Checklist

- [ ] `Decimal` for monetary values (no `float`)
- [ ] Currency from tenant settings (no hardcoded `DKK`)
- [ ] Locale from tenant settings (no hardcoded `da-DK`)
- [ ] All queries filter by tenant
- [ ] `@transaction.atomic` on multi-model operations
- [ ] Audit trail for all mutations
- [ ] Soft delete only (no `.delete()`)
- [ ] `.full_clean()` before `.save()`
- [ ] Closed period check before invoice modifications

---

## Refresh Rules

To update embedded rules after Oliver edits the Linear document:

1. Fetch latest:
   ```
   mcp__linear-server__get_document(id: "b05fc81b-b20d-41f2-9ffb-f4ceb62879c5")
   ```

2. Update the DOs/DON'Ts sections above

3. Update **LAST_SYNCED** timestamp

4. Commit to `claude-code-config` repo

---

## References

- [Linear Document](https://linear.app/crispa/document/accounting-rules-dos-and-donts-f470a2e9fbdb)
- [Notion Mirror](https://www.notion.so/Dos-and-Donts-Linear-Sync-2fd608f8081480758ab1da31b39f97e8)
- [CRI-30 - Custom Accounting Agent](https://linear.app/crispa/issue/CRI-30)
