# MCP Tools Test Suite

Comprehensive test suite voor alle 21 Sitecore MCP tools. Elke test valideert alle parameters en edge cases tegen een live Sitecore instance.

## 🚀 Quick Start

### Run Interactive Menu

```powershell
cd scripts/tests
.\run-mcp-tests.ps1
```

Het menu biedt:
- Individuele tool tests (1-21)
- Run all tests (A)
- Gedetailleerde resultaten per test
- Exit codes voor CI/CD integratie

### Run Specific Test

```powershell
.\test-mcp-get-item.ps1        # Test sitecore_get_item
.\test-mcp-search.ps1           # Test sitecore_search
.\test-mcp-get-children.ps1     # Test sitecore_get_children
```

### Run All Tests Programmatically

```powershell
# From test runner menu, select [A]
# Or call individual tests in sequence
```

## 📋 Test Coverage

### ✅ Implemented Tests

| # | MCP Tool | Test Script | Status |
|---|----------|-------------|--------|
| 1 | `sitecore_get_item` | `test-mcp-get-item.ps1` | ✅ Complete (10 tests) |
| 2 | `sitecore_get_children` | `test-mcp-get-children.ps1` | ✅ Complete (8 tests) |
| 3 | `sitecore_get_field_value` | `test-mcp-get-field-value.ps1` | ⏳ TODO |
| 4 | `sitecore_get_item_fields` | `test-mcp-get-item-fields.ps1` | ✅ Complete (8 tests) |
| 5 | `sitecore_query` | `test-mcp-query.ps1` | ✅ Complete (3 tests) |
| 6 | `sitecore_search` | `test-mcp-search.ps1` | ✅ Complete (8 tests) |
| 7 | `sitecore_search_paginated` | `test-mcp-search-paginated.ps1` | ⏳ TODO |
| 8 | `sitecore_get_template` | `test-mcp-get-template.ps1` | ✅ Complete (6 tests) |
| 9 | `sitecore_get_templates` | `test-mcp-get-templates.ps1` | ⏳ TODO |
| 10 | `sitecore_get_parent` | `test-mcp-get-parent.ps1` | ⏳ TODO |
| 11 | `sitecore_get_ancestors` | `test-mcp-get-ancestors.ps1` | ⏳ TODO |
| 12 | `sitecore_get_item_versions` | `test-mcp-get-item-versions.ps1` | ⏳ TODO |
| 13 | `sitecore_get_item_with_statistics` | `test-mcp-get-item-with-statistics.ps1` | ⏳ TODO |
| 14 | `sitecore_get_layout` | `test-mcp-get-layout.ps1` | ⏳ TODO |
| 15 | `sitecore_get_sites` | `test-mcp-get-sites.ps1` | ⏳ TODO |
| 16 | `sitecore_create_item` | `test-mcp-create-item.ps1` | ⏳ TODO |
| 17 | `sitecore_update_item` | `test-mcp-update-item.ps1` | ⏳ TODO |
| 18 | `sitecore_delete_item` | `test-mcp-delete-item.ps1` | ⏳ TODO |
| 19 | `sitecore_discover_item_dependencies` | `test-mcp-discover-dependencies.ps1` | ⏳ TODO |
| 20 | `sitecore_scan_schema` | `test-mcp-scan-schema.ps1` | ⏳ TODO |
| 21 | `sitecore_command` | `test-mcp-command.ps1` | ⏳ TODO |

**Progress**: 6/21 complete (29%)

## 🎯 Test Scenarios Per Tool

### sitecore_get_item (10 tests)
- ✅ Basic item retrieval (en)
- ✅ Dutch language (nl-NL)
- ✅ With version parameter
- ✅ By GUID
- ✅ Template item
- ✅ With fields
- ✅ With parent
- ✅ With children
- ✅ Non-existent item
- ✅ With URL

### sitecore_get_children (8 tests)
- ✅ Basic children
- ✅ With pagination
- ✅ hasChildren flag
- ✅ With template info
- ✅ With version
- ✅ Different language
- ✅ No children case
- ✅ With fields

### sitecore_get_item_fields (8 tests)
- ✅ All fields (ownFields: false)
- ✅ Own fields only (ownFields: true)
- ✅ Specific field by name
- ✅ Multiple standard fields
- ✅ With version
- ✅ Different language
- ✅ Template item fields
- ✅ Field count verification

### sitecore_search (8 tests)
- ✅ Keyword search
- ✅ With rootItem filter
- ✅ With language filter
- ✅ Pagination
- ✅ path_contains filter
- ✅ templateName filter
- ✅ Empty keyword (all items)
- ✅ Cursor pagination

### sitecore_query (3 tests)
- ✅ Simple path query
- ✅ Descendants query (//)
- ✅ Direct children query (/*)

### sitecore_get_template (6 tests)
- ✅ Basic template info
- ✅ With base templates
- ✅ With sections (children)
- ✅ Field definitions
- ✅ By GUID
- ✅ From templates folder

## 🔧 Test Framework

### Environment Setup

Tests gebruik maken van:
- `Load-DotEnv.ps1` voor environment variabelen
- `.env` file in repository root
- GraphQL endpoint: `/sitecore/api/graph/items/master`

**Required Environment Variables:**
```
SITECORE_HOST=https://your-instance.com
SITECORE_API_KEY=your-api-key
```

### Test Functions

Elk test script bevat:

```powershell
function Test-Query {
    param(
        [string]$TestName,
        [string]$Query,
        [scriptblock]$Validation
    )
    # Execute GraphQL query
    # Validate response
    # Track pass/fail
}
```

**Test Results:**
- Exit code `0` = All tests passed
- Exit code `N` = N tests failed
- Detailed console output per test

### Result Tracking

```powershell
$testResults = @{
    Passed = 0
    Failed = 0
    Tests = @(
        @{ Name = "Test Name"; Status = "PASS/FAIL"; Error = "..." }
    )
}
```

## 📊 Output Format

```
=== Testing sitecore_get_item ===

[TEST] Get item - Basic (en)
[PASS]

[TEST] Get item - Dutch language (nl-NL)
[PASS]

[TEST] Get item - Non-existent path
[PASS]

========================================
  Test Results: sitecore_get_item
========================================

Total Tests: 10
Passed: 10
Failed: 0
```

## 🎨 Color Coding

- **Cyan**: Headers and test names
- **Green**: Passed tests
- **Red**: Failed tests
- **Yellow**: Warnings and info
- **Gray**: Details and metadata

## 🚦 CI/CD Integration

Tests returnen proper exit codes:

```powershell
# Run all tests
$exitCode = & .\run-mcp-tests.ps1 -RunAll

# Check result
if ($exitCode -eq 0) {
    Write-Host "All tests passed!" -ForegroundColor Green
} else {
    Write-Host "$exitCode test(s) failed!" -ForegroundColor Red
    exit $exitCode
}
```

## 📝 Adding New Tests

1. **Create test script:**
   ```powershell
   # scripts/tests/test-mcp-your-tool.ps1
   . "$PSScriptRoot\..\tools\Load-DotEnv.ps1"
   Load-DotEnv -EnvFile "$PSScriptRoot\..\..\env"
   
   Write-Host "`n=== Testing sitecore_your_tool ===" -ForegroundColor Cyan
   # ... test implementation
   ```

2. **Add to test runner menu:**
   - Update `run-mcp-tests.ps1`
   - Add menu item
   - Add to `$tests` array in `Run-AllTests`

3. **Update this README:**
   - Add to coverage table
   - Document test scenarios

## 🎯 Best Practices

### Test Naming
- **Script**: `test-mcp-{tool-name}.ps1`
- **Test Cases**: Descriptive names like "Get item - Basic (en)"

### Query Structure
- Use proper GUID format: `{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}`
- Always specify language parameter
- Use meaningful paths (e.g., `/sitecore/content`)

### Validation
- Validate structure AND data
- Check for null/empty responses
- Verify field counts and types

### Error Handling
- Try/catch around GraphQL calls
- Check for `response.errors`
- Provide meaningful error messages

## 📚 Related Documentation

- **MCP Tools**: See `src/index.ts` for tool definitions
- **GraphQL Schema**: See `.github/introspectionSchema.json`
- **Type Definitions**: See `src/sitecore-types.ts`
- **Examples**: See `docs/guides/VOORBEELDEN.md`

## ⚠️ Known Limitations

- **Mutations**: Create/Update/Delete tests require cleanup logic
- **Introspection**: Schema scanning niet ondersteund door Sitecore
- **Query Syntax**: Sitecore query beperkt tot path/wildcard patterns

## 🤝 Contributing

Nieuwe tests welkom! Zie bovenstaand "Adding New Tests" voor guidelines.

**Priority voor nieuwe tests:**
1. ⏳ sitecore_get_parent
2. ⏳ sitecore_get_ancestors
3. ⏳ sitecore_get_item_versions
4. ⏳ sitecore_search_paginated
5. ⏳ sitecore_discover_item_dependencies
