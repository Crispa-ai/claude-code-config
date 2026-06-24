---
name: query-optimization-helper
description: Reference for optimising Django ORM queries and eliminating N+1 problems. Use when a view or endpoint is slow or makes excessive queries.
---

# Django Query Optimization Helper

**Quick reference guide for optimizing Django ORM queries and eliminating N+1 query problems.**

## The N+1 Query Problem

### What is it?

```python
# ❌ N+1 QUERY PROBLEM - Hits database N times
entries = JournalEntry.objects.all()  # 1 query
for entry in entries:
    print(entry.tenant.name)           # N queries (1 per entry)
    print(entry.account.code)          # N more queries
```

**Result**: For 100 entries, this makes 201 database queries!

### Why is it bad?

- **Performance**: Each query adds 10-50ms latency
- **Database load**: Overwhelms DB with unnecessary queries
- **Slow pages**: Users wait seconds for simple list views
- **Scalability**: Gets worse as data grows

## Solution 1: select_related()

**Use for**: ForeignKey and OneToOneField relationships

```python
# ✅ OPTIMIZED - Single query with JOIN
entries = JournalEntry.objects.select_related('tenant', 'account').all()
for entry in entries:
    print(entry.tenant.name)   # No additional query
    print(entry.account.code)  # No additional query
```

**Result**: Only 1 query for 100 entries!

### How select_related() Works

- Performs SQL JOIN at database level
- Fetches related objects in same query
- Related objects cached in memory
- No additional queries when accessing relations

### When to Use select_related()

- Accessing ForeignKey fields in loops
- Displaying related object data in lists
- Any time you access relation.field
- Template rendering with related objects

### Example: Invoice List

```python
# ❌ BAD - N+1 queries
invoices = Invoice.objects.all()
for invoice in invoices:
    print(f"{invoice.customer.name}: ${invoice.total}")
    # Each invoice.customer hits database

# ✅ GOOD - Single query
invoices = Invoice.objects.select_related('customer').all()
for invoice in invoices:
    print(f"{invoice.customer.name}: ${invoice.total}")
    # No additional queries
```

## Solution 2: prefetch_related()

**Use for**: ManyToManyField and reverse ForeignKey relationships

```python
# ❌ N+1 QUERY PROBLEM
invoices = Invoice.objects.all()
for invoice in invoices:
    for line in invoice.lines.all():  # N queries
        print(line.description)

# ✅ OPTIMIZED - Two queries total
invoices = Invoice.objects.prefetch_related('lines').all()
for invoice in invoices:
    for line in invoice.lines.all():  # No additional queries
        print(line.description)
```

### How prefetch_related() Works

- Makes separate query for related objects
- Uses Python to join results
- Related objects cached in memory
- More efficient than N individual queries

### When to Use prefetch_related()

- Accessing reverse relations (invoice.lines)
- ManyToManyField relations
- GenericForeignKey relations
- When select_related() isn't available

### Example: User with Roles

```python
# ❌ BAD - N+1 queries
users = User.objects.all()
for user in users:
    for role in user.roles.all():  # M2M field, N queries
        print(role.name)

# ✅ GOOD - Two queries
users = User.objects.prefetch_related('roles').all()
for user in users:
    for role in user.roles.all():  # No additional queries
        print(role.name)
```

## Combining select_related() and prefetch_related()

You can use both in the same query:

```python
# ✅ OPTIMAL - Fetch everything efficiently
invoices = Invoice.objects \
    .select_related('customer', 'tenant') \
    .prefetch_related('lines', 'lines__product') \
    .all()

for invoice in invoices:
    print(invoice.customer.name)        # select_related
    print(invoice.tenant.slug)          # select_related
    for line in invoice.lines.all():    # prefetch_related
        print(line.product.name)        # prefetch_related (nested)
```

## Advanced: Prefetch Objects

For complex filtering on related objects:

```python
from django.db.models import Prefetch

# Only prefetch active lines, with their products
active_lines = InvoiceLine.objects.filter(active=True).select_related('product')

invoices = Invoice.objects.prefetch_related(
    Prefetch('lines', queryset=active_lines, to_attr='active_lines')
)

for invoice in invoices:
    for line in invoice.active_lines:  # Only active lines
        print(line.product.name)
```

## Other Optimization Techniques

### only() - Fetch Specific Fields

```python
# ✅ Only fetch fields you need
users = User.objects.only('id', 'email', 'first_name')
# Excludes all other fields from query
```

### defer() - Exclude Specific Fields

```python
# ✅ Exclude large fields
articles = Article.objects.defer('content', 'html_content')
# Fetches all fields except content fields
```

### values() - Get Dictionaries

```python
# ✅ When you don't need full model instances
users = User.objects.values('id', 'email')
# Returns: [{'id': 1, 'email': 'user@example.com'}, ...]
```

### values_list() - Get Tuples

```python
# ✅ When you only need specific fields as tuples
emails = User.objects.values_list('email', flat=True)
# Returns: ['user1@example.com', 'user2@example.com', ...]
```

## Quick Decision Tree

```
Are you accessing a related object?
│
├─ ForeignKey or OneToOneField?
│  └─ Use select_related('relation_name')
│
├─ ManyToManyField or Reverse ForeignKey?
│  └─ Use prefetch_related('relation_name')
│
└─ Multiple levels deep?
   └─ Use select_related('relation__nested_relation')
      or prefetch_related('relation__nested_relation')
```

## Common Patterns in DRF

### Viewset Query Optimization

```python
class InvoiceViewSet(viewsets.ModelViewSet):
    queryset = Invoice.objects.all()
    serializer_class = InvoiceSerializer

    def get_queryset(self):
        # ✅ IMPORTANT: Optimize queryset based on serializer needs
        queryset = super().get_queryset()

        if self.action == 'list':
            # List view needs customer and tenant
            queryset = queryset.select_related('customer', 'tenant')

        elif self.action == 'retrieve':
            # Detail view needs everything
            queryset = queryset.select_related('customer', 'tenant') \
                               .prefetch_related('lines', 'lines__product')

        return queryset
```

### Serializer Optimization

```python
class InvoiceSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    line_count = serializers.SerializerMethodField()

    class Meta:
        model = Invoice
        fields = ['id', 'customer_name', 'line_count', 'total']

    def get_line_count(self, obj):
        # ✅ Assumes lines are prefetched
        return obj.lines.count()  # Uses cached data if prefetched
```

**Corresponding ViewSet:**
```python
queryset = Invoice.objects \
    .select_related('customer') \
    .prefetch_related('lines')
```

## Debugging N+1 Queries

### Django Debug Toolbar

Install and enable Django Debug Toolbar to see all queries:

```bash
pip install django-debug-toolbar
```

Shows:
- Number of queries per page
- Duplicate queries (sign of N+1)
- Query execution time

### nplusone Library

```bash
pip install nplusone
```

```python
# settings.py
MIDDLEWARE = [
    'nplusone.ext.django.NPlusOneMiddleware',
    # ... other middleware
]

NPLUSONE_RAISE = True  # Raises exception on N+1
```

### Manual Query Counting

```python
from django.db import connection
from django.test.utils import override_settings

@override_settings(DEBUG=True)
def test_query_count():
    # Reset query log
    connection.queries_log.clear()

    # Run your code
    invoices = Invoice.objects.all()
    for invoice in invoices:
        print(invoice.customer.name)

    # Check query count
    print(f"Queries: {len(connection.queries)}")
    for query in connection.queries:
        print(query['sql'])
```

## Real-World Example

### Before Optimization

```python
# ❌ Terrible performance
def get_transaction_list(request):
    transactions = Transaction.objects.filter(tenant=request.tenant)
    # 1 query to fetch transactions

    data = []
    for tx in transactions:
        data.append({
            'id': tx.id,
            'account': tx.account.name,       # N queries
            'category': tx.category.name,     # N queries
            'tenant': tx.tenant.name,         # N queries
            'vendor': tx.vendor.name if tx.vendor else None,  # N queries
        })
    # Total: 1 + 4N queries for N transactions
    # For 100 transactions: 401 queries, ~4-5 seconds

    return JsonResponse(data, safe=False)
```

### After Optimization

```python
# ✅ Excellent performance
def get_transaction_list(request):
    transactions = Transaction.objects \
        .filter(tenant=request.tenant) \
        .select_related('account', 'category', 'tenant', 'vendor')
    # 1 query with JOINs

    data = []
    for tx in transactions:
        data.append({
            'id': tx.id,
            'account': tx.account.name,       # No query
            'category': tx.category.name,     # No query
            'tenant': tx.tenant.name,         # No query
            'vendor': tx.vendor.name if tx.vendor else None,  # No query
        })
    # Total: 1 query for any number of transactions
    # For 100 transactions: 1 query, ~50ms

    return JsonResponse(data, safe=False)
```

**Result**: 8000% performance improvement!

## Checklist for Every Viewset

When creating a DRF viewset:

- [ ] Check serializer for related fields
- [ ] Add select_related() for ForeignKey fields
- [ ] Add prefetch_related() for reverse/M2M relations
- [ ] Test with Django Debug Toolbar
- [ ] Verify query count doesn't grow with data size
- [ ] Document optimization in code comments

## Summary

| Relationship Type | Solution | SQL Behavior |
|------------------|----------|--------------|
| ForeignKey | `select_related()` | JOIN in single query |
| OneToOneField | `select_related()` | JOIN in single query |
| ManyToManyField | `prefetch_related()` | Separate query + Python join |
| Reverse ForeignKey | `prefetch_related()` | Separate query + Python join |

**Golden Rule**: If you access a relation in a loop, optimize the queryset!
