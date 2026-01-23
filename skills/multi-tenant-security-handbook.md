# Multi-Tenant Security Handbook

**Complete guide to tenant isolation, authentication, security, and data protection in multi-tenant Django applications.**

## When to Use

- When implementing new tenant-aware features
- When debugging tenant isolation issues
- When reviewing authentication code
- When implementing new API endpoints
- Before deploying tenant-related changes

## Tenant Isolation Principles

### Critical Rules

1. **EVERY query MUST be tenant-aware** - No exceptions
2. **NEVER trust client-provided tenant IDs** - Always use authenticated tenant
3. **Test cross-tenant access** - Verify users can't access other tenants' data
4. **Authentication REQUIRED** - All tenant pages must be protected

---

## Django Tenant Isolation Patterns

### Pattern 1: Tenant Middleware

```python
# middleware/tenant_middleware.py
class TenantMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Extract tenant from subdomain or header
        tenant_slug = self.get_tenant_slug(request)

        # Load tenant
        try:
            request.tenant = Tenant.objects.get(slug=tenant_slug)
        except Tenant.DoesNotExist:
            return HttpResponseNotFound('Tenant not found')

        response = self.get_response(request)
        return response

    def get_tenant_slug(self, request):
        # From subdomain: acme.crispa.ai → acme
        host = request.get_host()
        slug = host.split('.')[0]
        return slug
```

### Pattern 2: Tenant-Aware Managers

```python
# models/base.py
class TenantAwareManager(models.Manager):
    def get_queryset(self):
        # Automatically filter by current tenant
        queryset = super().get_queryset()
        if hasattr(self, 'tenant'):
            queryset = queryset.filter(tenant=self.tenant)
        return queryset

class TenantModel(models.Model):
    tenant = models.ForeignKey('tenants.Tenant', on_delete=models.CASCADE)
    objects = TenantAwareManager()

    class Meta:
        abstract = True
```

### Pattern 3: Tenant Context Manager

```python
# utils/tenant_context.py
from contextvars import ContextVar

_tenant_context = ContextVar('tenant', default=None)

def get_current_tenant():
    return _tenant_context.get()

def set_current_tenant(tenant):
    _tenant_context.set(tenant)

@contextmanager
def tenant_context(tenant):
    """Use in tests or Celery tasks"""
    token = _tenant_context.set(tenant)
    try:
        yield
    finally:
        _tenant_context.reset(token)

# Usage in Celery task:
@shared_task
def process_invoices(tenant_id):
    tenant = Tenant.objects.get(id=tenant_id)
    with tenant_context(tenant):
        # All queries use this tenant
        invoices = Invoice.objects.all()
```

### Pattern 4: Viewset Tenant Filtering

```python
# api/views/invoice_viewset.py
class InvoiceViewSet(viewsets.ModelViewSet):
    queryset = Invoice.objects.all()
    serializer_class = InvoiceSerializer

    def get_queryset(self):
        # ✅ REQUIRED: Filter by request tenant
        return super().get_queryset().filter(tenant=self.request.tenant)

    def perform_create(self, serializer):
        # ✅ REQUIRED: Set tenant on creation
        serializer.save(tenant=self.request.tenant)
```

---

## Authentication Patterns

### Frontend Authentication (Next.js + Auth0)

**Pattern 1: withAuthenticationRequired (Recommended)**

```typescript
// pages/[tenant]/invoices/index.tsx
import { withAuthenticationRequired } from "@auth0/auth0-react";

function InvoicesPage() {
    // Page content
}

// CRITICAL: Both are required
export default withAuthenticationRequired(InvoicesPage);

export const getServerSideProps = async () => {
    return { props: {} };  // Forces SSR
};
```

**Why both are required:**
- `withAuthenticationRequired`: Auth0 client-side redirect to login
- `getServerSideProps`: Forces SSR so Next.js router is available

**Pattern 2: getServerSideProps with Session Check**

```typescript
// pages/[tenant]/admin/settings.tsx
import { getSession } from "@auth0/nextjs-auth0";

export const getServerSideProps = async (context) => {
    const session = await getSession(context.req, context.res);

    if (!session) {
        return {
            redirect: {
                destination: "/login",
                permanent: false,
            },
        };
    }

    // Optional: Check permissions
    if (!session.user.isAdmin) {
        return {
            redirect: {
                destination: `/${context.params.tenant}/unauthorized`,
                permanent: false,
            },
        };
    }

    return {
        props: {
            user: session.user,
        },
    };
};

function SettingsPage({ user }) {
    return <div>Settings for {user.email}</div>;
}

export default SettingsPage;
```

### Backend Authentication (Django + JWT)

**Pattern 1: Authentication Classes**

```python
# api/views/base.py
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication

class BaseViewSet(viewsets.ModelViewSet):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Tenant from authenticated user
        return super().get_queryset().filter(
            tenant=self.request.user.tenant
        )
```

**Pattern 2: Custom Permissions**

```python
# api/permissions.py
from rest_framework import permissions

class IsTenantMember(permissions.BasePermission):
    """User must belong to the tenant"""

    def has_permission(self, request, view):
        return (
            request.user.is_authenticated and
            request.tenant == request.user.tenant
        )

class IsTenantOwner(permissions.BasePermission):
    """User must be tenant owner"""

    def has_object_permission(self, request, view, obj):
        return (
            request.user.is_authenticated and
            obj.tenant == request.user.tenant and
            request.user.role == 'owner'
        )
```

---

## Security Vulnerabilities to Prevent

### Vulnerability 1: IDOR (Insecure Direct Object Reference)

```python
# ❌ VULNERABLE: Client controls which invoice to access
def get_invoice(request, invoice_id):
    invoice = Invoice.objects.get(id=invoice_id)  # No tenant check!
    return JsonResponse(invoice.to_dict())

# Attacker can access any invoice by guessing IDs

# ✅ SECURE: Filter by tenant
def get_invoice(request, invoice_id):
    invoice = Invoice.objects.get(
        id=invoice_id,
        tenant=request.tenant  # REQUIRED
    )
    return JsonResponse(invoice.to_dict())

# Or use get_object_or_404 with tenant filter
invoice = get_object_or_404(
    Invoice,
    id=invoice_id,
    tenant=request.tenant
)
```

### Vulnerability 2: Mass Assignment

```python
# ❌ VULNERABLE: Client can set tenant_id
def create_invoice(request):
    data = request.data  # {"tenant_id": 123, "amount": 100}
    invoice = Invoice.objects.create(**data)  # Client controls tenant!
    return JsonResponse(invoice.to_dict())

# ✅ SECURE: Never trust client for tenant
def create_invoice(request):
    data = request.data
    data.pop('tenant_id', None)  # Remove if present
    invoice = Invoice.objects.create(
        tenant=request.tenant,  # From auth, not client
        **data
    )
    return JsonResponse(invoice.to_dict())
```

### Vulnerability 3: GraphQL/API Field Exposure

```python
# ❌ VULNERABLE: Exposes tenant_id in API
class InvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Invoice
        fields = ['id', 'tenant_id', 'amount', 'customer']
        # Client can see and potentially modify tenant_id

# ✅ SECURE: Don't expose tenant_id
class InvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Invoice
        fields = ['id', 'amount', 'customer']
        read_only_fields = ['id']
        # tenant_id not included
```

### Vulnerability 4: JWT Token Tampering

```python
# ❌ VULNERABLE: Trust client-provided tenant
@api_view(['GET'])
def get_data(request):
    tenant_slug = request.headers.get('X-Tenant')  # Client controlled!
    tenant = Tenant.objects.get(slug=tenant_slug)
    # ...

# ✅ SECURE: Tenant from JWT claims
@api_view(['GET'])
def get_data(request):
    # Tenant extracted during authentication
    tenant = request.tenant  # From JWT, verified by backend
    # ...
```

---

## Testing Tenant Isolation

### Test 1: Cross-Tenant Data Access

```python
# tests/test_tenant_isolation.py
import pytest
from apps.accounting.models import Invoice

@pytest.mark.django_db
def test_users_cannot_access_other_tenants_invoices(
    client, user1, user2, tenant1, tenant2
):
    """User from tenant1 cannot access tenant2's invoices"""

    # Create invoice for tenant1
    invoice1 = Invoice.objects.create(
        tenant=tenant1,
        amount=100,
        number="INV-001"
    )

    # Create invoice for tenant2
    invoice2 = Invoice.objects.create(
        tenant=tenant2,
        amount=200,
        number="INV-002"
    )

    # Authenticate as tenant1 user
    client.force_authenticate(user=user1)

    # Try to access tenant1's invoice - should succeed
    response = client.get(f'/api/invoices/{invoice1.id}/')
    assert response.status_code == 200
    assert response.data['number'] == 'INV-001'

    # Try to access tenant2's invoice - should fail
    response = client.get(f'/api/invoices/{invoice2.id}/')
    assert response.status_code == 404  # Not found (tenant mismatch)

    # List endpoint should only return tenant1's invoices
    response = client.get('/api/invoices/')
    assert response.status_code == 200
    assert len(response.data['results']) == 1
    assert response.data['results'][0]['id'] == invoice1.id
```

### Test 2: Tenant in URL vs Authentication

```python
@pytest.mark.django_db
def test_tenant_url_must_match_auth(client, user1, tenant1, tenant2):
    """Tenant in URL must match authenticated user's tenant"""

    # Authenticate as tenant1 user
    client.force_authenticate(user=user1)

    # Try to access tenant2's URL
    response = client.get(f'/api/{tenant2.slug}/invoices/')

    # Should fail with 403 or redirect
    assert response.status_code in [403, 404]
```

### Test 3: Manager Filtering

```python
@pytest.mark.django_db
def test_manager_filters_by_tenant(tenant1, tenant2):
    """Manager automatically filters by current tenant"""

    # Create invoices for different tenants
    invoice1 = Invoice.objects.create(tenant=tenant1, amount=100)
    invoice2 = Invoice.objects.create(tenant=tenant2, amount=200)

    # Set tenant context
    with tenant_context(tenant1):
        # Should only see tenant1's invoices
        invoices = Invoice.objects.all()
        assert invoices.count() == 1
        assert invoices.first().id == invoice1.id

    with tenant_context(tenant2):
        # Should only see tenant2's invoices
        invoices = Invoice.objects.all()
        assert invoices.count() == 1
        assert invoices.first().id == invoice2.id
```

---

## Automated Security Checks

### Pre-Deployment Checklist

```bash
# 1. Check all tenant pages have authentication
yarn check:page-auth

# 2. Run tenant isolation tests
docker compose exec backend pytest -m tenant_isolation

# 3. Check for hardcoded tenant IDs
grep -r "tenant_id.*=" apps/ | grep -v "request.tenant"

# 4. Verify API endpoints filter by tenant
grep -r "objects.all()" apps/*/api/views/ | grep -v "filter(tenant"
```

### Automated Test Script

```python
# scripts/test_tenant_security.py
"""
Automated tenant security tests
Run: python manage.py shell < scripts/test_tenant_security.py
"""

from django.contrib.auth.models import User
from apps.tenants.models import Tenant
from apps.accounting.models import Invoice

print("🔒 Testing Tenant Security\n")

# Create test tenants
tenant1 = Tenant.objects.create(name="Tenant 1", slug="tenant1")
tenant2 = Tenant.objects.create(name="Tenant 2", slug="tenant2")

# Create test data
invoice1 = Invoice.objects.create(tenant=tenant1, amount=100)
invoice2 = Invoice.objects.create(tenant=tenant2, amount=200)

# Test 1: Query without tenant filter
print("Test 1: Unfiltered queries...")
all_invoices = Invoice.objects.all()
if all_invoices.count() == 2:
    print("⚠️  WARNING: Queries not filtered by tenant")
else:
    print("✅ Queries properly filtered")

# Test 2: Can access cross-tenant data?
print("\nTest 2: Cross-tenant access...")
with tenant_context(tenant1):
    tenant1_invoices = Invoice.objects.all()
    if invoice2 in tenant1_invoices:
        print("❌ FAIL: Can access other tenant's data!")
    else:
        print("✅ PASS: Proper tenant isolation")

# Cleanup
tenant1.delete()
tenant2.delete()
print("\n✅ Security tests complete")
```

---

## Common Mistakes

### Mistake 1: Forgetting Tenant Filter

```python
# ❌ WRONG
def get_recent_invoices():
    return Invoice.objects.all()[:10]  # Returns ALL tenants' invoices!

# ✅ CORRECT
def get_recent_invoices(tenant):
    return Invoice.objects.filter(tenant=tenant).all()[:10]
```

### Mistake 2: Using Primary Keys in URLs

```python
# ❌ RISKY: Sequential IDs are guessable
/api/invoices/1234/

# ✅ BETTER: Use UUIDs
/api/invoices/a1b2c3d4-e5f6-7890-abcd-ef1234567890/

# In model:
import uuid
class Invoice(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
```

### Mistake 3: Tenant in JWT but Not Used

```python
# ❌ WRONG: JWT has tenant but code doesn't use it
def get_invoices(request):
    # JWT contains tenant claim
    # But query doesn't use it
    return Invoice.objects.all()

# ✅ CORRECT: Extract and use tenant from JWT
def get_invoices(request):
    tenant = request.tenant  # From JWT claims
    return Invoice.objects.filter(tenant=tenant)
```

---

## Emergency Response: Tenant Data Leak

If tenant data is accidentally exposed:

```bash
# 1. Immediately revoke access
# Rotate JWT secrets
export JWT_SECRET=$(openssl rand -base64 32)
# Force all users to re-login

# 2. Audit data access logs
docker compose exec backend python manage.py shell
>>> from apps.audit.models import AccessLog
>>> suspicious = AccessLog.objects.filter(
...     tenant_mismatch=True
... )
>>> print(f"Suspicious accesses: {suspicious.count()}")

# 3. Notify affected tenants
# Send security notification emails

# 4. Fix vulnerability and deploy
# Add tests to prevent recurrence
```

---

## Summary Checklist

**For Every New Feature:**
- [ ] All queries filter by `tenant=request.tenant`
- [ ] All API endpoints authenticated
- [ ] No client-provided tenant IDs trusted
- [ ] Cross-tenant access tests written
- [ ] UUIDs used instead of sequential IDs
- [ ] Tenant pages have `withAuthenticationRequired`
- [ ] Run `yarn check:page-auth`
- [ ] Run tenant isolation tests

**For Every Deployment:**
- [ ] Review all tenant-related changes
- [ ] Run full test suite including tenant tests
- [ ] Check for hardcoded tenant IDs
- [ ] Verify authentication on all new pages

Multi-tenant security is not optional - it's the foundation of the entire system.
