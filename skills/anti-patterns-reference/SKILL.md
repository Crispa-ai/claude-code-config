---
name: anti-patterns-reference
description: Historical reference of past Crispa production incidents, security breaches, and data-corruption events. Use during code review, onboarding, or when deciding whether to allow an exception to a coding rule.
---

# Anti-Patterns Reference

**Historical incident reference documenting past production issues, security breaches, and data corruption events. Each pattern includes what happened, why it was dangerous, and how to prevent it.**

## When to Use

- During code review to explain why certain patterns are banned
- When onboarding new team members
- When debating whether to allow an exception to coding rules
- To understand the "why" behind validation checks

---

## Production Incidents

### 1. Hardcoded Secrets in Version Control

**What Happened:**
Doppler tokens were committed during debugging. The tokens are now in git history forever.

**The Code:**
```yaml
# ❌ BANNED - Committed to version control
env:
  DOPPLER_TOKEN: dp.sa.xxx

# ✅ REQUIRED - Use secrets management
env:
  DOPPLER_TOKEN: ${{ secrets.DOPPLER_TOKEN }}
```

**Why Dangerous:**
- Secrets in git history can never be fully removed
- Anyone with repo access can extract credentials
- Automated scanners find exposed secrets within hours

**Prevention:**
- NEVER hardcode tokens, API keys, passwords, or credentials in ANY file
- NEVER commit "temporary" debugging credentials
- If a secret touches version control, rotate it within the hour
- Use pre-commit hooks to detect secrets

---

### 2. Hardcoded IDs Breaking Across Environments

**What Happened:**
Slack user IDs were hardcoded. The feature worked in dev, broke in staging, broke differently in prod.

**The Code:**
```python
# ❌ BANNED - IDs are environment-specific
user_ids = ['U09PTSKAXRS', 'U03KRDK9LPM']

# ✅ REQUIRED - Dynamic lookup
user = slack_client.users_lookupByEmail(email=user_email)
```

**Why Dangerous:**
- IDs differ between environments (dev, staging, prod)
- IDs differ between Slack workspaces
- Silent failures - code works but affects wrong users

**Prevention:**
- NEVER hardcode user IDs, tenant IDs, Slack IDs, or any external resource IDs
- Use email, slug, or other stable identifiers
- Look up resources dynamically

---

### 3. N+1 Queries Destroying Performance

**What Happened:**
List views took 30+ seconds because of missing query optimization. This happened multiple times.

**The Code:**
```python
# ❌ BANNED - Hits DB once per iteration
for entry in JournalEntry.objects.all():
    print(entry.tenant.name)  # N+1 QUERY!

# ✅ REQUIRED - Single query
for entry in JournalEntry.objects.select_related('tenant'):
    print(entry.tenant.name)  # Already loaded
```

**Why Dangerous:**
- 100 entries = 101 database queries
- Response times grow linearly with data
- Timeouts and poor user experience

**Prevention:**
- ALWAYS use `select_related()` for ForeignKey
- ALWAYS use `prefetch_related()` for reverse relations
- If serializer accesses related objects, viewset MUST optimize query

---

### 4. OAuth Errors Losing Tenant Context

**What Happened:**
Users got redirected to `/error` with no context. Support couldn't help them. Users couldn't retry.

**The Code:**
```python
# ❌ BANNED - Context lost
return redirect('/error')

# ✅ REQUIRED - Preserve tenant context
return redirect(f'/{tenant_slug}/error?message={error}')
```

**Why Dangerous:**
- Users stranded with no way back
- Support can't identify which tenant or user
- No retry path available

**Prevention:**
- OAuth state MUST include tenant_slug
- Error redirects MUST preserve tenant context
- Log EVERYTHING: tenant, user, error type, stack trace

---

### 5. Webhook Verification Returning True

**What Happened:**
The Plaid webhook verification function returned `True` unconditionally. Anyone could forge webhook requests and inject fake transactions.

**The Code:**
```python
# ❌ SECURITY BREACH - Allows forged requests
def verify_webhook(body, headers):
    return True  # "TODO: implement later"

# ✅ REQUIRED - Actual verification
def verify_webhook(body, headers):
    signature = headers.get('Plaid-Verification')
    expected = hmac.new(secret, body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(signature, expected)
```

**Why Dangerous:**
- CRITICAL security vulnerability
- Attackers can inject fake financial data
- No audit trail - fake data looks legitimate

**Prevention:**
- NEVER return `True` from verification functions
- NEVER merge webhook endpoints without signature verification
- ALWAYS use `hmac.compare_digest()` for constant-time comparison

---

### 6. Console.log Left in Production

**What Happened:**
20+ files shipped with `console.log` statements. Customer data appeared in browser consoles.

**The Code:**
```typescript
// ❌ BANNED - Data exposure
console.log('user data:', userData)

// ✅ REQUIRED - Proper logging
import { logger } from '@/lib/logger'
logger.debug('user data:', userData)
```

**Why Dangerous:**
- Customer PII visible in browser console
- Performance impact from logging
- Unprofessional appearance

**Prevention:**
- NEVER use `console.log`, `console.error`, `console.warn` in production code
- Use `frontend/src/lib/logger.js`
- Enable `no-console` ESLint rule

---

### 7. TypeScript `any` Everywhere

**What Happened:**
72+ files use `any`, making TypeScript useless. Bugs that should be caught at compile time reach production.

**The Code:**
```typescript
// ❌ BANNED - Defeats TypeScript's purpose
const data: any[] = []
const handler = (value: any) => { ... }

// ✅ REQUIRED - Define actual types
interface LineItem { id: string; amount: number }
const data: LineItem[] = []
const handler = (value: string | number) => { ... }
```

**Why Dangerous:**
- Type errors reach production
- Refactoring becomes impossible (no safety net)
- Documentation value of TypeScript lost

**Prevention:**
- NEVER use `any`
- Use `unknown` if type is truly unknown
- Define interfaces and use union types
- If absolutely must use `any`, add eslint-disable with justification

---

### 8. Hardcoded Locales and Currency

**What Happened:**
Danish locale `da-DK` and currency `DKK` were hardcoded. International customers saw wrong formats.

**The Code:**
```typescript
// ❌ BANNED - Single locale assumption
new Intl.NumberFormat('da-DK').format(amount)
currency = details.get("currency", "DKK")

// ✅ REQUIRED - Dynamic locale
new Intl.NumberFormat(tenant.locale).format(amount)
currency = details["currency"]  # Fail if missing
```

**Why Dangerous:**
- Wrong currency display for non-Danish customers
- Financial confusion and trust issues
- Silent failures (code works but shows wrong data)

**Prevention:**
- NEVER hardcode locales, date formats, number formats, or currencies
- Use tenant settings
- Financial data without explicit currency is a bug—fail fast

---

### 9. `.save()` Without `.full_clean()`

**What Happened:**
Django's `.save()` does NOT call validators. Invalid data was written to the database.

**The Code:**
```python
# ❌ BANNED - Validators not called
self.save()

# ✅ REQUIRED - Validate first
self.full_clean()
self.save()
```

**Why Dangerous:**
- Model validators completely bypassed
- Invalid data persists in database
- Data corruption discovered later, harder to fix

**Prevention:**
- ALWAYS call `.full_clean()` before `.save()` for user-facing operations
- Serializers validate automatically; direct model saves do not
- Consider using `Model.save()` override to enforce this

---

### 10. Multi-Step Operations Without Transactions

**What Happened:**
Invoice was created, but line creation failed. Database left with orphaned invoice, no lines. Data corruption.

**The Code:**
```python
# ❌ BANNED - Partial writes on failure
invoice = Invoice.objects.create(**data)
for line in lines:
    InvoiceLine.objects.create(invoice=invoice, **line)  # If this fails...

# ✅ REQUIRED - All or nothing
from django.db import transaction

@transaction.atomic
def create_invoice_with_lines(data):
    invoice = Invoice.objects.create(**data)
    for line in lines:
        InvoiceLine.objects.create(invoice=invoice, **line)
```

**Why Dangerous:**
- Partial data states corrupt business logic
- Orphaned records hard to detect and fix
- Financial totals become inconsistent

**Prevention:**
- ALWAYS wrap multi-model operations in `@transaction.atomic`
- No exceptions

---

### 11. Error Handling as TODO Comments

**What Happened:**
15+ hooks had `// TODO: handle error`. Errors were silently swallowed. Users saw nothing. Debugging was impossible.

**The Code:**
```typescript
// ❌ BANNED - Silent failures
catch (error) {
  // TODO: handle error
}

// ✅ REQUIRED - Proper handling
catch (error) {
  toast.error('Operation failed. Please try again.')
  Sentry.captureException(error)
}
```

**Why Dangerous:**
- Users get no feedback when things fail
- Developers have no visibility into errors
- Bugs persist because no one knows they exist

**Prevention:**
- NEVER leave `// TODO: handle error`
- Show user feedback
- Log to Sentry
- Every error must be visible somewhere

---

### 12. Security Bypass Flags

**What Happened:**
Settings like `SKIP_SIGNATURE_VERIFICATION` allowed bypassing security in any environment. One wrong config and production is exposed.

**The Code:**
```python
# ❌ BANNED - Can be enabled anywhere
if getattr(settings, "SKIP_VERIFICATION", False):
    return True

# ✅ ACCEPTABLE - Environment-gated only
if settings.ENVIRONMENT == "development":
    return True

# ✅ BEST - Use test mocks, not production bypasses
```

**Why Dangerous:**
- Config mistake enables bypass in production
- No audit trail when bypass is used
- Security assumed but not guaranteed

**Prevention:**
- NEVER create settings that bypass security checks
- Use `ENVIRONMENT == "development"` if absolutely necessary
- Prefer test mocks over production code bypasses

---

## Quick Reference Checklist

**REJECT code that violates ANY of these:**

- [ ] No secrets, tokens, or credentials in code
- [ ] No hardcoded IDs (user, tenant, resource)
- [ ] No hardcoded locales, currencies, or date formats
- [ ] Webhook verification actually verifies (never `return True`)
- [ ] No `console.log` in production code
- [ ] No `any` types in TypeScript
- [ ] All queries use `select_related`/`prefetch_related` where needed
- [ ] No environment variable defaults (fail fast)
- [ ] `.full_clean()` called before direct `.save()` calls
- [ ] Multi-model operations wrapped in `@transaction.atomic`
- [ ] All errors have user feedback and Sentry logging
- [ ] OAuth flows preserve tenant context
- [ ] No `// TODO: handle error` or empty catch blocks

---

## The Principle Behind These Rules

Every check on this list exists because it caught or prevented a production incident:

1. **Fail Fast** - Errors should be immediate and visible, not silent and delayed
2. **Defense in Depth** - Multiple layers of validation catch different issues
3. **No Silent Defaults** - Explicit is better than implicit
4. **Security by Default** - Security can't be optional or configurable
5. **Data Integrity First** - Database consistency is non-negotiable

These aren't arbitrary style preferences—they're battle-tested safeguards that protect the system and its users.
