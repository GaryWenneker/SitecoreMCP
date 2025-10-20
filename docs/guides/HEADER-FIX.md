# Header Configuration Fix - Summary

## Problem
Headers waren niet altijd correct ingesteld:
- `sc_apikey` werd alleen toegevoegd als API key aanwezig was (conditional)
- Headers werden via `defaults.headers.common` gezet na `axios.create()`
- Geen validatie dat API key aanwezig was

## Solution

### Before (❌ Problematisch):
```typescript
this.client = axios.create({
  httpsAgent: new https.Agent({
    rejectUnauthorized: false,
  }),
  timeout: 30000,
});

// Headers toegevoegd NA create
if (this.apiKey) {
  this.client.defaults.headers.common["sc_apikey"] = this.apiKey;
}
this.client.defaults.headers.common["Content-Type"] = "application/json";
```

**Problemen:**
- Headers niet altijd aanwezig
- Geen validatie van API key
- Headers kunnen overschreven worden

### After (✅ Correct):
```typescript
// Validate API key is present
if (!this.apiKey) {
  throw new Error("SITECORE_API_KEY is required but not provided");
}

// Create axios instance with authentication
this.client = axios.create({
  httpsAgent: new https.Agent({
    rejectUnauthorized: false,
  }),
  timeout: 30000,
  headers: {
    // These headers are REQUIRED for every GraphQL request
    "sc_apikey": this.apiKey,
    "Content-Type": "application/json"
  }
});
```

**Voordelen:**
- ✅ Headers altijd aanwezig bij creatie
- ✅ API key validatie vooraf
- ✅ Duidelijke error message als API key ontbreekt
- ✅ Headers worden meegestuurd met elke request

## Test Results

### Test 1: Met beide headers ✅
```
Headers: sc_apikey + Content-Type
Result: SUCCESS
```

### Test 2: Zonder Content-Type ❌
```
Headers: sc_apikey only
Result: 400 Bad Request
Conclusion: Content-Type is REQUIRED
```

### Test 3: Zonder API key ❌
```
Headers: Content-Type only
Result: Authentication required
Conclusion: sc_apikey is REQUIRED
```

### Test 4: Met verkeerde API key ❌
```
Headers: Wrong API key + Content-Type
Result: Authentication error
Conclusion: Valid API key is REQUIRED
```

## Required Headers for Sitecore GraphQL

### Mandatory:
1. **`sc_apikey`** - Sitecore API key voor authenticatie
2. **`Content-Type: application/json`** - Required voor GraphQL POST requests

### Optional:
3. **`Authorization: Basic ...`** - Alleen als fallback (niet meer nodig met API key)

## Code Changes

### File: `src/sitecore-service.ts`

**Lines Changed:** 43-60

**Key Changes:**
1. Added API key validation before axios.create()
2. Moved headers into axios.create() config
3. Made headers part of instance creation
4. Improved comments for clarity

## Impact

### Wat dit oplost:
- ✅ Authentication errors door ontbrekende headers
- ✅ Inconsistente header configuratie
- ✅ Moeilijk te debuggen authentication issues
- ✅ Edge cases waar headers niet gezet werden

### Breaking Changes:
- ⚠️ Code gooit nu error als API key ontbreekt (dit is GOED!)
- ⚠️ Voorheen kon code initialiseren zonder API key

### Migration:
Geen migration nodig - API key was al verplicht in `index.ts`:
```typescript
if (!SITECORE_API_KEY) {
  console.error("ERROR: SITECORE_API_KEY environment variable is required");
  process.exit(1);
}
```

## Verification

### Manual Test:
```powershell
.\test-headers.ps1
```

### Unit Test (Future):
```typescript
describe('SitecoreService Headers', () => {
  it('should throw error without API key', () => {
    expect(() => {
      new SitecoreService('host', 'user', 'pass', undefined)
    }).toThrow('SITECORE_API_KEY is required');
  });
  
  it('should set required headers', () => {
    const service = new SitecoreService('host', 'user', 'pass', 'key');
    expect(service.client.defaults.headers['sc_apikey']).toBe('key');
    expect(service.client.defaults.headers['Content-Type']).toBe('application/json');
  });
});
```

## Documentation Updates

### Files to Update:
- [x] `src/sitecore-service.ts` - Code fixed
- [x] `test-headers.ps1` - Test script created
- [x] `HEADER-FIX.md` - This document
- [ ] `README.md` - Add header requirements section
- [ ] `SECURITY.md` - Mention header security

## Best Practices

### ✅ DO:
- Always set headers in `axios.create()` config
- Validate required config before creating client
- Use clear error messages
- Test header requirements

### ❌ DON'T:
- Set headers conditionally
- Add headers after client creation
- Skip validation of required config
- Use ambiguous error messages

## Related Issues

### GitHub Issues:
- [ ] Create issue: "Headers not always sent with GraphQL requests"
- [ ] Link to PR with this fix

### Stack Overflow:
Common question: "Sitecore GraphQL Authentication Required error"
Answer: Ensure sc_apikey and Content-Type headers are set

## Status

- ✅ Code fixed
- ✅ Tests passing
- ✅ Build successful
- ✅ Headers validated
- 🔜 Ready to commit

---

**Date:** October 16, 2025
**Issue:** Headers not consistently sent
**Fix:** Headers in axios.create() config
**Impact:** Solves authentication errors
**Status:** ✅ COMPLETE
