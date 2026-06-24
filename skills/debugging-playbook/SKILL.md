---
name: debugging-playbook
description: Playbook for diagnosing common issues in Crispa's Django + Next.js stack. Use when triaging 500s, failed deploys, or stuck background tasks.
---

# Debugging Playbook

**Quick reference for diagnosing and fixing common issues in Django + Next.js applications.**

## Quick Index

- [Frontend Issues](#frontend-issues)
- [Backend Issues](#backend-issues)
- [Database Issues](#database-issues)
- [API & Integration Issues](#api--integration-issues)
- [Performance Issues](#performance-issues)
- [Authentication Issues](#authentication-issues)

---

## Frontend Issues

### Issue: "Loading Crispa" Spinner Forever

**Symptoms:**
- Page stuck on loading spinner
- No API requests in Network tab
- No errors in console

**Cause:** Auth0 session state corruption

**Quick Fix:**
```javascript
// Run in browser console:
localStorage.clear();
sessionStorage.clear();
location.reload();
```

**Permanent Fix:**
- Check Auth0 configuration
- Verify callback URLs match
- Check if auth token expired

---

### Issue: "Hydration Mismatch" Error

**Symptoms:**
```
Error: Hydration failed because the initial UI does not match
```

**Causes:**
1. Server and client render different HTML
2. Date/time formatting differences
3. Conditional rendering based on browser APIs

**Fixes:**
```typescript
// ❌ WRONG: Using browser API during SSR
function Component() {
    const width = window.innerWidth;  // window not defined on server
    return <div>{width}</div>;
}

// ✅ CORRECT: Check if browser
function Component() {
    const [width, setWidth] = useState(null);

    useEffect(() => {
        setWidth(window.innerWidth);
    }, []);

    return <div>{width}</div>;
}

// ✅ CORRECT: Use 'use client' directive
'use client';
function Component() {
    const width = window.innerWidth;
    return <div>{width}</div>;
}
```

---

### Issue: MUI Styles Not Applied

**Symptoms:**
- Components render but have no styling
- Layout broken
- Default browser styles showing

**Causes:**
1. Server-side rendering style mismatch
2. Missing theme provider
3. Emotion cache issues

**Fixes:**
```typescript
// Check 1: ThemeProvider wraps app
// pages/_app.tsx
import { ThemeProvider } from '@mui/material/styles';
import theme from '@/styles/theme';

function MyApp({ Component, pageProps }) {
    return (
        <ThemeProvider theme={theme}>
            <Component {...pageProps} />
        </ThemeProvider>
    );
}

// Check 2: Emotion cache configured for SSR
// pages/_document.tsx
import createEmotionServer from '@emotion/server/create-instance';
import createEmotionCache from '@/lib/createEmotionCache';

// See MUI docs for complete setup
```

---

### Issue: React Hook Dependency Warnings

**Symptoms:**
```
React Hook useEffect has a missing dependency: 'fetchData'
```

**Fixes:**
```typescript
// ❌ WRONG: Ignoring the warning
useEffect(() => {
    fetchData();
}, []); // Missing dependency

// ✅ OPTION 1: Add dependency (may cause infinite loop)
useEffect(() => {
    fetchData();
}, [fetchData]);

// ✅ OPTION 2: Use useCallback
const fetchData = useCallback(async () => {
    // fetch logic
}, [/* dependencies */]);

useEffect(() => {
    fetchData();
}, [fetchData]);

// ✅ OPTION 3: Move function inside useEffect
useEffect(() => {
    async function fetchData() {
        // fetch logic
    }
    fetchData();
}, [/* dependencies of fetchData */]);
```

---

### Issue: Network Request Failed / CORS

**Symptoms:**
```
Access to fetch at 'http://backend:8000/api/' from origin 'http://localhost:3000'
has been blocked by CORS policy
```

**Fixes:**
```python
# backend/settings/development.py
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:3001",
    "http://frontend:3000",  # Docker network
]

# Or for development only:
CORS_ALLOW_ALL_ORIGINS = True  # Never use in production!
```

```typescript
// frontend: Use correct API URL
// .env.local
NEXT_PUBLIC_API_URL=http://localhost:8000

// api client
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://backend:8000';
```

---

## Backend Issues

### Issue: Django Admin Not Loading Static Files

**Symptoms:**
- Admin interface has no CSS/JS
- Plain unstyled HTML

**Fix:**
```bash
# Collect static files
docker compose exec backend python manage.py collectstatic --no-input

# Check static files configuration
# settings.py
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# In docker-compose.yml, ensure volume is mounted:
volumes:
  - ./backend/staticfiles:/app/staticfiles
```

---

### Issue: Migrations Out of Order

**Symptoms:**
```
django.db.migrations.exceptions.InconsistentMigrationHistory
```

**Cause:** Multiple developers created migrations simultaneously

**Fix:**
```bash
# Option 1: Merge migrations
docker compose exec backend python manage.py makemigrations --merge

# Option 2: Fake migrations to align state
docker compose exec backend python manage.py migrate --fake accounting 0042
docker compose exec backend python manage.py migrate

# Option 3: Reset migrations (last resort, development only)
# Delete migration files (keep __init__.py)
# Drop and recreate database
docker compose down -v
docker compose up -d db
docker compose exec backend python manage.py makemigrations
docker compose exec backend python manage.py migrate
```

---

### Issue: Import Error / ModuleNotFoundError

**Symptoms:**
```
ModuleNotFoundError: No module named 'apps.accounting'
```

**Causes:**
1. Module not installed
2. Wrong Python path
3. Circular imports

**Fixes:**
```bash
# Check installed packages
docker compose exec backend pip list | grep package-name

# Install missing package
docker compose exec backend pip install package-name

# Check Python path
docker compose exec backend python -c "import sys; print('\n'.join(sys.path))"

# Fix circular imports
# Move shared code to utils or separate module
# Use late imports (import inside function)
```

---

### Issue: Database Connection Refused

**Symptoms:**
```
django.db.utils.OperationalError: could not connect to server: Connection refused
```

**Fixes:**
```bash
# Check database container is running
docker compose ps db

# Check database logs
docker compose logs db

# Restart database
docker compose restart db

# Check connection settings
# .env.local
DATABASE_HOST=db  # Use service name in Docker
DATABASE_PORT=5432
DATABASE_NAME=crispa_db
DATABASE_USER=postgres
DATABASE_PASSWORD=your_password

# Test connection manually
docker compose exec backend python manage.py dbshell
```

---

### Issue: Serializer Validation Errors

**Symptoms:**
```
{"detail": "This field is required."}
{"detail": "This field may not be null."}
```

**Debug:**
```python
# In viewset, print validation errors
class InvoiceViewSet(viewsets.ModelViewSet):
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print(f"Validation errors: {serializer.errors}")
            # Check what data was sent
            print(f"Request data: {request.data}")
        return super().create(request, *args, **kwargs)
```

**Common causes:**
```python
# Missing required field
data = {"name": "Invoice"}  # Missing "amount"

# Wrong field name
data = {"invoice_number": "INV-001"}  # Field is "number", not "invoice_number"

# Wrong data type
data = {"amount": "100.50"}  # Should be Decimal or float, not string

# Null value for non-nullable field
data = {"amount": None}  # Field doesn't allow null
```

---

## Database Issues

### Issue: Too Many Database Queries (N+1)

**Symptoms:**
- Slow API responses
- Django Debug Toolbar shows 100+ queries
- Same query repeated many times

**Diagnosis:**
```python
# Enable query logging
from django.db import connection

def my_view(request):
    invoices = Invoice.objects.all()
    for invoice in invoices:
        print(invoice.customer.name)  # N+1 problem

    print(f"Queries: {len(connection.queries)}")
    for query in connection.queries:
        print(query['sql'])
```

**Fix:**
```python
# Use select_related for ForeignKey
invoices = Invoice.objects.select_related('customer', 'tenant').all()

# Use prefetch_related for reverse FK and M2M
invoices = Invoice.objects.prefetch_related('lines', 'lines__product').all()

# Both together
invoices = Invoice.objects \
    .select_related('customer', 'tenant') \
    .prefetch_related('lines', 'lines__product') \
    .all()
```

**See:** `query-optimization-helper.md` for complete guide

---

### Issue: Database Locked (SQLite only)

**Symptoms:**
```
sqlite3.OperationalError: database is locked
```

**Fix:** Use PostgreSQL instead
```bash
# This should never happen in production
# SQLite is not suitable for multi-threaded Django apps
# Always use PostgreSQL
```

---

### Issue: Unique Constraint Violation

**Symptoms:**
```
django.db.utils.IntegrityError: duplicate key value violates unique constraint
```

**Diagnosis:**
```python
# Check if record already exists
existing = Invoice.objects.filter(number='INV-001').first()
if existing:
    print(f"Invoice INV-001 already exists: {existing.id}")

# Check model constraints
print(Invoice._meta.constraints)
```

**Fixes:**
```python
# Option 1: Update instead of create
invoice, created = Invoice.objects.update_or_create(
    number='INV-001',
    defaults={'amount': 100}
)

# Option 2: Handle the error
try:
    Invoice.objects.create(number='INV-001', amount=100)
except IntegrityError:
    # Update existing or use different number
    invoice = Invoice.objects.get(number='INV-001')
    invoice.amount = 100
    invoice.save()
```

---

## API & Integration Issues

### Issue: Plaid Webhook Not Received

**Diagnosis:**
```bash
# Check webhook URL is accessible
curl -X POST https://yourdomain.com/api/plaid/webhook \
  -H "Content-Type: application/json" \
  -d '{"webhook_type": "TEST"}'

# Check logs
docker compose logs backend | grep webhook

# Check Plaid dashboard for webhook deliveries
# https://dashboard.plaid.com/team/webhooks
```

**Common causes:**
1. URL not publicly accessible (localhost won't work)
2. HTTPS required for production
3. Webhook verification failing
4. Firewall blocking requests

**Fixes:**
```python
# 1. Use ngrok for local testing
# ngrok http 8000
# Set webhook URL: https://abc123.ngrok.io/api/plaid/webhook

# 2. Fix webhook verification
def verify_plaid_webhook(request):
    signature = request.headers.get('Plaid-Verification')
    body = request.body
    expected = hmac.new(
        settings.PLAID_WEBHOOK_SECRET.encode(),
        body,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(signature, expected)

# 3. Log all webhook calls
@csrf_exempt
def plaid_webhook(request):
    logger.info(f"Webhook received: {request.body}")
    logger.info(f"Headers: {request.headers}")
    # Process webhook
```

---

### Issue: API Returns 500 Internal Server Error

**Diagnosis:**
```bash
# Check backend logs
docker compose logs backend | tail -50

# Check for Python exceptions
docker compose logs backend | grep -A 10 "Traceback"

# Enable DEBUG mode (development only)
# .env.local
DEBUG=True
```

**Common causes:**
1. Unhandled exception in view
2. Missing database migration
3. Missing environment variable
4. Serializer error

**Fix: Add proper error handling**
```python
from rest_framework.views import exception_handler as drf_exception_handler
import logging

logger = logging.getLogger(__name__)

def custom_exception_handler(exc, context):
    # Log the exception
    logger.error(f"API Exception: {exc}", exc_info=True)

    # Call DRF's default handler
    response = drf_exception_handler(exc, context)

    if response is None:
        # Unhandled exception
        logger.error(f"Unhandled exception in {context['view']}")
        response = Response(
            {"detail": "Internal server error"},
            status=500
        )

    return response

# settings.py
REST_FRAMEWORK = {
    'EXCEPTION_HANDLER': 'apps.api.exceptions.custom_exception_handler',
}
```

---

### Issue: API Returns Empty Response

**Symptoms:**
- API call succeeds (200 OK)
- Response body is empty or `{}`
- Frontend shows no data

**Diagnosis:**
```python
# Add debugging to viewset
class InvoiceViewSet(viewsets.ModelViewSet):
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        print(f"Queryset count: {queryset.count()}")
        print(f"First 5 IDs: {list(queryset.values_list('id', flat=True)[:5])}")
        return super().list(request, *args, **kwargs)
```

**Common causes:**
1. Tenant filter excludes all records
2. Serializer excludes all fields
3. Pagination returns wrong page

**Fixes:**
```python
# Check tenant filter
print(f"Request tenant: {request.tenant}")
print(f"User tenant: {request.user.tenant}")

# Check serializer fields
serializer = InvoiceSerializer(invoice)
print(f"Serialized data: {serializer.data}")

# Check pagination
response = self.list(request)
print(f"Response data keys: {response.data.keys()}")
# Should have: count, next, previous, results
```

---

## Performance Issues

### Issue: Slow Page Load

**Diagnosis:**
```bash
# Frontend: Check Network tab in DevTools
# - Look for slow API calls (> 1s)
# - Look for large payloads (> 1MB)
# - Look for many requests (> 20)

# Backend: Enable Django Debug Toolbar
# docker-compose.yml
environment:
  - DEBUG=True
  - DJANGO_DEBUG_TOOLBAR=True

# Check query counts
# Should be < 20 queries per request
```

**Common causes:**
1. N+1 queries (see query optimization)
2. Large unoptimized images
3. Too much data returned
4. No caching

**Fixes:**
```python
# Backend: Add pagination
class InvoiceViewSet(viewsets.ModelViewSet):
    pagination_class = PageNumberPagination

# Backend: Use .only() to fetch specific fields
Invoice.objects.only('id', 'number', 'amount')

# Backend: Add caching
from django.core.cache import cache

def get_invoice_summary(invoice_id):
    cache_key = f"invoice_summary_{invoice_id}"
    summary = cache.get(cache_key)

    if summary is None:
        invoice = Invoice.objects.get(id=invoice_id)
        summary = calculate_summary(invoice)
        cache.set(cache_key, summary, timeout=3600)  # 1 hour

    return summary

# Frontend: Use React Query caching
const { data } = useQuery(
    ['invoices', tenant],
    fetchInvoices,
    { staleTime: 5 * 60 * 1000 }  // 5 minutes
);

# Frontend: Implement virtual scrolling for long lists
import { FixedSizeList } from 'react-window';
```

---

### Issue: Memory Leak

**Symptoms:**
- Container memory usage keeps growing
- Eventually crashes with OOM error
- Slower over time

**Diagnosis:**
```bash
# Monitor container memory
docker stats

# Backend: Profile memory usage
# Install memory_profiler
pip install memory-profiler

# Add to function
from memory_profiler import profile

@profile
def process_transactions():
    # Function code
    pass

# Run: python -m memory_profiler script.py
```

**Common causes:**
1. Large querysets not paginated
2. Files not closed
3. Circular references
4. Cache never cleared

**Fixes:**
```python
# Use iterator() for large querysets
for invoice in Invoice.objects.iterator(chunk_size=100):
    process_invoice(invoice)

# Close files explicitly
with open('file.txt', 'r') as f:
    data = f.read()
# File automatically closed

# Clear cache periodically
cache.clear()

# Celery: Limit tasks per worker
command: celery -A backend worker --max-tasks-per-child=1000
```

---

## Authentication Issues

### Issue: "Invalid token" Error

**Symptoms:**
```
{"detail": "Given token not valid for any token type"}
```

**Diagnosis:**
```python
# Check token expiration
from rest_framework_simplejwt.tokens import AccessToken

token = AccessToken(token_string)
print(f"Expires at: {token['exp']}")
print(f"User ID: {token['user_id']}")

# Check token format
print(f"Token parts: {len(token_string.split('.'))}")  # Should be 3
```

**Fixes:**
```python
# Increase token lifetime (development only)
# settings.py
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=24),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
}

# Frontend: Handle token refresh
async function fetchWithAuth(url) {
    let response = await fetch(url, {
        headers: {
            'Authorization': `Bearer ${accessToken}`
        }
    });

    if (response.status === 401) {
        // Token expired, refresh it
        accessToken = await refreshToken();
        response = await fetch(url, {
            headers: {
                'Authorization': `Bearer ${accessToken}`
            }
        });
    }

    return response;
}
```

---

### Issue: Auth0 Callback Error

**Symptoms:**
```
Error: invalid_request
Description: Missing required parameter: code
```

**Fixes:**
```typescript
// Check Auth0 config
// .env.local
NEXT_PUBLIC_AUTH0_DOMAIN=your-tenant.auth0.com
NEXT_PUBLIC_AUTH0_CLIENT_ID=your_client_id
NEXT_PUBLIC_AUTH0_REDIRECT_URI=http://localhost:3000/api/auth/callback

// Check callback URL in Auth0 dashboard matches exactly
// Including protocol (http/https) and port
```

---

## Emergency Commands

```bash
# Reset everything
docker compose down -v && docker compose up -d && yarn migrate && yarn seed

# Clear all caches
docker compose exec backend python manage.py shell -c "from django.core.cache import cache; cache.clear()"
docker compose exec redis redis-cli FLUSHALL

# Check all services
docker compose ps && docker compose logs --tail=10

# Restart specific service
docker compose restart backend celery_worker

# Connect to database
docker compose exec db psql -U postgres -d crispa_db

# Django shell
docker compose exec backend python manage.py shell
```

---

## Quick Checklist for Any Issue

1. ✅ Check logs (`docker compose logs <service>`)
2. ✅ Check service is running (`docker compose ps`)
3. ✅ Check environment variables (`.env.local` files)
4. ✅ Try restarting service (`docker compose restart <service>`)
5. ✅ Check database state (migrations, data)
6. ✅ Search error message in codebase
7. ✅ Check recent code changes (`git log`)
8. ✅ Try on another machine/environment

Most issues are solved by steps 1-4!
