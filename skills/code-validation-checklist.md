# Code Validation Checklist

**Quick validation procedure for ensuring code meets CLAUDE.md standards before committing.**

## When to Use

- Before committing changes
- During code review
- When debugging failed CI/CD checks
- Before deploying to staging or production

## Quick Validation Script

Run this complete validation check on staged changes:

```bash
#!/bin/bash
echo "=== CODE VALIDATION CHECKLIST ==="
echo ""

# Stage changes if not already staged
git add -A
FILES=$(git diff --cached --name-only)

if [ -z "$FILES" ]; then
    echo "ℹ️  No staged changes to validate"
    exit 0
fi

echo "📁 Files to validate:"
echo "$FILES"
echo ""

FAILED=0

# 🔒 SECURITY CHECKS

echo "🔒 Security Checks"
echo "=================="

# 1. Secrets/Tokens
echo -n "1. Secrets/tokens.............. "
RESULT=$(git diff --cached -- ':!CLAUDE.md' ':!*.md' ':!.claude-shared/**' | grep -v '^-' | grep -iE '(api_key|secret|token|password|credential|dp\.sa\.|sk_live|sk_test|Bearer [A-Za-z0-9])' | head -3)
if [ -n "$RESULT" ]; then
    echo "❌ FAIL"
    echo "   Found potential secrets:"
    echo "$RESULT" | sed 's/^/   /'
    FAILED=1
else
    echo "✅ PASS"
fi

# 2. Hardcoded IDs
echo -n "2. Hardcoded IDs............... "
RESULT=$(git diff --cached -- ':!CLAUDE.md' ':!*.md' ':!.claude-shared/**' | grep -v '^-' | grep -E "'U[A-Z0-9]{10}'|\"U[A-Z0-9]{10}\"" | head -3)
if [ -n "$RESULT" ]; then
    echo "❌ FAIL"
    echo "   Found hardcoded IDs:"
    echo "$RESULT" | sed 's/^/   /'
    FAILED=1
else
    echo "✅ PASS"
fi

# 3. Webhook Verification
echo -n "3. Webhook verification........ "
RESULT=$(git diff --cached | grep -A5 "verify.*webhook" | grep "return True" | head -3)
if [ -n "$RESULT" ]; then
    echo "❌ FAIL"
    echo "   Found webhook returning True unconditionally"
    FAILED=1
else
    echo "✅ PASS"
fi

echo ""

# 📝 CODE QUALITY CHECKS

echo "📝 Code Quality Checks"
echo "======================"

# 4. console.log
echo -n "4. console.log................. "
RESULT=$(git diff --cached -- '*.ts' '*.tsx' '*.js' '*.jsx' | grep -v '^-' | grep -E 'console\.(log|error|warn|debug)' | head -3)
if [ -n "$RESULT" ]; then
    echo "❌ FAIL"
    echo "   Found console.log statements:"
    echo "$RESULT" | sed 's/^/   /'
    FAILED=1
else
    echo "✅ PASS"
fi

# 5. TypeScript any
echo -n "5. TypeScript any.............. "
RESULT=$(git diff --cached -- '*.ts' '*.tsx' | grep -v '^-' | grep -E ': any[^a-zA-Z]|<any>|\(.*: any\)' | head -3)
if [ -n "$RESULT" ]; then
    echo "❌ FAIL"
    echo "   Found TypeScript any types:"
    echo "$RESULT" | sed 's/^/   /'
    FAILED=1
else
    echo "✅ PASS"
fi

# 6. TODO error handling
echo -n "6. TODO error handling......... "
RESULT=$(git diff --cached -- ':!CLAUDE.md' ':!*.md' ':!.claude-shared/**' | grep -v '^-' | grep -iE 'TODO.*error|catch.*\{\s*\}|except.*:\s*pass' | head -3)
if [ -n "$RESULT" ]; then
    echo "❌ FAIL"
    echo "   Found TODO/empty error handling:"
    echo "$RESULT" | sed 's/^/   /'
    FAILED=1
else
    echo "✅ PASS"
fi

echo ""

# 🌍 LOCALIZATION CHECKS

echo "🌍 Localization Checks"
echo "======================"

# 7. Hardcoded locales
echo -n "7. Hardcoded locales........... "
RESULT=$(git diff --cached -- ':!CLAUDE.md' ':!*.md' ':!.claude-shared/**' ':!*.test.*' ':!*test*' | grep -v '^-' | grep -E "'da-DK'|'DKK'|\"da-DK\"|\"DKK\"" | head -3)
if [ -n "$RESULT" ]; then
    echo "❌ FAIL"
    echo "   Found hardcoded locales:"
    echo "$RESULT" | sed 's/^/   /'
    FAILED=1
else
    echo "✅ PASS"
fi

echo ""

# ⚡ PERFORMANCE CHECKS

echo "⚡ Performance Checks"
echo "====================="

# 8. N+1 Queries (Django)
echo -n "8. N+1 queries (Django)........ "
# Check for loops accessing relations without select_related/prefetch_related
RESULT=$(git diff --cached -- '*.py' | grep -A3 "\.all()\|\.filter(" | grep -E "for .* in .*:" | head -3)
if [ -n "$RESULT" ]; then
    # Check if select_related or prefetch_related is used
    if ! git diff --cached -- '*.py' | grep -qE "select_related|prefetch_related"; then
        echo "⚠️  WARNING"
        echo "   Found loops over querysets - verify select_related/prefetch_related usage"
    else
        echo "✅ PASS"
    fi
else
    echo "✅ PASS"
fi

echo ""

# 🔐 AUTHENTICATION CHECKS

echo "🔐 Authentication Checks"
echo "========================"

# 9. Tenant page authentication
echo -n "9. Tenant page auth............ "
if echo "$FILES" | grep -q 'pages/\[tenant\]'; then
    TENANT_FILES=$(echo "$FILES" | grep 'pages/\[tenant\].*\.tsx\|pages/\[tenant\].*\.jsx')
    AUTH_MISSING=""
    for file in $TENANT_FILES; do
        if [ -f "$file" ]; then
            if ! grep -q "withAuthenticationRequired\|getSession" "$file"; then
                AUTH_MISSING="$AUTH_MISSING\n   - $file"
            fi
        fi
    done
    if [ -n "$AUTH_MISSING" ]; then
        echo "❌ FAIL"
        echo "   Tenant pages missing authentication:"
        echo -e "$AUTH_MISSING"
        FAILED=1
    else
        echo "✅ PASS"
    fi
else
    echo "✅ PASS (no tenant pages)"
fi

echo ""

# 🚫 CONFIGURATION CHECKS

echo "🚫 Configuration Checks"
echo "======================="

# 10. Environment variable defaults (Python)
echo -n "10. Env var defaults........... "
RESULT=$(git diff --cached -- '*.py' ':!CLAUDE.md' | grep -v '^-' | grep -E 'os\.getenv\([^)]+,[^)]+\)|getattr\(settings,[^,]+,[^)]+\)' | head -3)
if [ -n "$RESULT" ]; then
    echo "❌ FAIL"
    echo "   Found environment variables with defaults:"
    echo "$RESULT" | sed 's/^/   /'
    FAILED=1
else
    echo "✅ PASS"
fi

echo ""

# 🏗️ DEPLOYMENT CHECKS

echo "🏗️  Deployment Checks"
echo "====================="

# 11. Branch protection
echo -n "11. Branch protection.......... "
BRANCH=$(git branch --show-current)
if [[ "$BRANCH" == "staging" || "$BRANCH" == "production" ]]; then
    echo "❌ FAIL"
    echo "   On protected branch: $BRANCH"
    echo "   All changes to protected branches must go through PRs"
    FAILED=1
else
    echo "✅ PASS (on $BRANCH)"
fi

# 12. Django model validation
echo -n "12. Django model validation.... "
RESULT=$(git diff --cached -- '*.py' | grep -A3 "\.save()" | grep -B3 -v "full_clean()" | grep "\.save()" | head -3)
if [ -n "$RESULT" ]; then
    echo "⚠️  WARNING"
    echo "   Found .save() without .full_clean() - verify validation is called"
else
    echo "✅ PASS"
fi

echo ""
echo "=== VALIDATION COMPLETE ==="
echo ""

if [ $FAILED -eq 1 ]; then
    echo "❌ VALIDATION FAILED"
    echo ""
    echo "Please fix the issues above before committing."
    echo "Run this script again after fixes."
    exit 1
else
    echo "✅ ALL CHECKS PASSED"
    echo ""
    echo "Code is ready to commit!"
    exit 0
fi
```

## Save as Executable Script

To use this repeatedly:

```bash
# Save to repository root
cat > validate-code.sh << 'EOF'
[paste the script above]
EOF

# Make executable
chmod +x validate-code.sh

# Run anytime
./validate-code.sh
```

## Individual Check Commands

If you want to run specific checks:

### Check for Secrets
```bash
git diff --cached | grep -iE '(api_key|secret|token|password|credential)'
```

### Check for console.log
```bash
git diff --cached -- '*.ts' '*.tsx' '*.js' '*.jsx' | grep 'console\.'
```

### Check for TypeScript any
```bash
git diff --cached -- '*.ts' '*.tsx' | grep -E ': any[^a-zA-Z]'
```

### Check Tenant Page Authentication
```bash
yarn check:page-auth
```

### Check for Hardcoded IDs
```bash
git diff --cached | grep -E "'U[A-Z0-9]{10}'"
```

## Common Fixes

### Remove console.log
```bash
# Find all console.log
grep -rn "console\." --include="*.ts" --include="*.tsx" frontend/

# Replace with logger
import { logger } from '@/lib/logger'
logger.debug('message', data)
```

### Fix TypeScript any
```typescript
// ❌ Before
const data: any = fetchData()

// ✅ After
interface DataType {
    id: string;
    value: number;
}
const data: DataType = fetchData()
```

### Add Tenant Page Auth
```typescript
// Add to top
import { withAuthenticationRequired } from "@auth0/auth0-react";

// Wrap export
export default withAuthenticationRequired(MyPage);

// Add SSR
export const getServerSideProps = async () => {
    return { props: {} };
};
```

### Remove Env Var Defaults
```python
# ❌ Before
host = os.getenv('HOST', 'localhost')

# ✅ After
host = os.environ['HOST']  # Fails fast if missing
```

## Integration with Git Hooks

Add as pre-commit hook:

```bash
# .git/hooks/pre-commit
#!/bin/bash
./validate-code.sh
exit $?
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

Now validation runs automatically before every commit!

## Why Each Check Matters

Every check on this list exists because it caught or prevented a production incident:

- **Secrets**: Prevent credential leaks
- **Hardcoded IDs**: Avoid environment-specific bugs
- **console.log**: Keep production code clean
- **TypeScript any**: Maintain type safety
- **Hardcoded locales**: Support internationalization
- **Env var defaults**: Fail fast on config issues
- **TODO errors**: Ensure proper error handling
- **Branch protection**: Enforce PR workflow
- **Tenant page auth**: Prevent security vulnerabilities
- **Webhook verification**: Stop forged requests
- **N+1 queries**: Maintain performance

This checklist is your first line of defense against code quality issues!
