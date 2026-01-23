# Clear Auth0 Cache

Use this skill when the frontend is stuck on "Loading Crispa" spinner with no API requests being made.

## Symptoms
- Page shows "Loading Crispa" spinner indefinitely
- No API requests in Network tab (only healthz checks)
- No JavaScript errors in console
- Auth0 appears stuck in loading state

## Root Cause
Stale or corrupted Auth0 tokens in browser localStorage/sessionStorage causing Auth0 to get stuck in a loading loop.

## Fix

### Option 1: Browser Console (Manual)
Ask the user to open browser DevTools (F12) → Console tab and run:
```javascript
localStorage.clear(); sessionStorage.clear(); location.reload();
```

### Option 2: Puppeteer (Automated)
Use puppeteer to clear storage and reload:

```
mcp__puppeteer__puppeteer_navigate to https://localhost:3000
mcp__puppeteer__puppeteer_evaluate with script: localStorage.clear(); sessionStorage.clear(); location.reload();
```

### Option 3: Incognito Mode
Ask the user to try the app in an incognito/private browser window to confirm the issue is cache-related.

## Prevention
This typically happens after:
- Auth0 session expiration during app updates
- Browser crashes during authentication
- Major frontend deployments that change Auth0 config
- Clearing cookies but not localStorage

## Related Files
- `frontend/src/core/providers/UserProvider.jsx` - Contains the loading logic
- Auth0 configuration in environment variables
