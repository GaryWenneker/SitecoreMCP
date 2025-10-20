# TestFeatures Discovery Test - README

## 📋 Overview

Dit script test de complete Helix architecture navigation en relationship discovery voor de **TestFeatures** feature module. Het valideert dat de Sitecore MCP server correct alle gerelateerde items kan vinden volgens de Helix principes.

## 🎯 Wat Dit Script Test

### Phase 1: Template Discovery
- ✅ Search in `/sitecore/templates/Feature/TestFeatures`
- ✅ Get template folder met item() query
- ✅ Get alle children (templates, folders, subfolders)

### Phase 2: Rendering Discovery
- ✅ Search in `/sitecore/layout/Renderings/Feature/TestFeatures`
- ✅ Get rendering folder met children
- ✅ List alle rendering definitions

### Phase 3: Content Resolver Discovery
- ✅ Search in `/sitecore/system/Modules/Layout Service/Rendering Contents Resolvers/Feature/TestFeatures`
- ✅ Get resolver folder met children
- ✅ List alle content resolvers

### Phase 4: Content Item Discovery
- ✅ Search alle content items in `/sitecore/content`
- ✅ Find items die TestFeatures templates gebruiken
- ✅ List alle instanties

### Phase 5: Global Search
- ✅ Search entire Sitecore database voor "TestFeatures"
- ✅ Group results by location
- ✅ Show distribution across paths

### Phase 6: Helix Relationship Validation
- ✅ Template-based content discovery
- ✅ Validate Feature → Content relationships
- ✅ Confirm Helix architecture compliance

## 🚀 Usage

### Option 1: Direct Script Execution (Requires .env)

```powershell
# Ensure .env file exists with credentials
.\test-testfeatures-discovery.ps1
```

**Required .env contents:**
```env
SITECORE_HOST=https://your-sitecore-instance.com
SITECORE_API_KEY=your-api-key-here
```

### Option 2: Via MCP Server (RECOMMENDED)

**In Claude Desktop:**
```
Find all TestFeatures items in Sitecore using the MCP tools:
1. Search templates in /sitecore/templates/Feature/TestFeatures
2. Search renderings in /sitecore/layout/Renderings/Feature/TestFeatures
3. Search content items using TestFeatures templates
4. Show me the complete Helix relationship map
```

**In VS Code Copilot:**
```
@workspace Use sitecore MCP tools to discover all TestFeatures module items:
- Templates
- Renderings
- Resolvers
- Content items
Show the complete inventory
```

## 📊 Expected Output

### Test Statistics
```
Total Tests: 10
Passed: 10
Failed: 0
```

### Discovered Items by Category
```
Templates: X items
Renderings: Y items
Resolvers: Z items
Content Items: N items
Search Results: M items
```

### Complete Item Inventory
Alle gevonden items met:
- ID
- Name
- Path
- Template
- Language

### Helix Relationship Map
```
Feature Module: TestFeatures

  Template Location:
    /sitecore/templates/Feature/TestFeatures
    Items: X

  Rendering Location:
    /sitecore/layout/Renderings/Feature/TestFeatures
    Items: Y

  Resolver Location:
    /sitecore/system/.../Feature/TestFeatures
    Items: Z

  Content Items:
    /sitecore/content/**/*
    Items: N
```

## 🔍 What It Validates

### Helix Architecture Compliance
1. ✅ Templates are in Feature layer (`/sitecore/templates/Feature/TestFeatures`)
2. ✅ Renderings are in Feature layer (`/sitecore/layout/Renderings/Feature/TestFeatures`)
3. ✅ Resolvers are in Feature layer (`/sitecore/system/.../Feature/TestFeatures`)
4. ✅ Content items reference Feature templates

### MCP Tool Functionality
1. ✅ `search()` query works with ContentSearchResult schema
2. ✅ `item()` query works with Item schema
3. ✅ `children()` query returns correct results
4. ✅ Template-based discovery works
5. ✅ Path-based filtering works
6. ✅ Language defaults are correct ('en' for system items)

### GraphQL Schema Correctness
1. ✅ No `url` errors (uses `uri`)
2. ✅ No `language { name }` errors (uses `language` String)
3. ✅ No `template { id, name }` errors in ContentSearchResult
4. ✅ Correct field access patterns

## 🐛 Troubleshooting

### Error: "SITECORE_API_KEY not found"

**Solution:**
1. Create `.env` file in project root
2. Add required credentials:
   ```env
   SITECORE_HOST=https://your-sitecore-instance.com
   SITECORE_API_KEY=your-api-key-here
   ```

### Error: "GraphQL Error: Cannot query field..."

**Solution:**
- Run `npm run build` to ensure latest fixes are compiled
- Check `SCHEMA-FIX-COMPLETE.md` for known schema issues
- Verify you're using correct ContentSearchResult fields

### No Items Found

**Possible Reasons:**
1. TestFeatures module doesn't exist in your Sitecore instance
2. Different path structure (not Feature layer)
3. Different naming convention
4. Language mismatch (try 'nl' or other languages)

**Solution:**
- Check if TestFeatures exists: Browse to `/sitecore/templates` in Sitecore
- Modify script paths to match your structure
- Adjust language parameter if needed

## 📝 Customization

### Test Different Feature

Change feature name on line 18:
```powershell
Write-Host "[INFO] Feature: YourFeatureName" -ForegroundColor Yellow
```

Then update all queries to search for `"YourFeatureName"` instead of `"TestFeatures"`.

### Test Different Layers

Modify paths to test Foundation or Project layers:
```graphql
# Foundation
rootItem: "/sitecore/templates/Foundation/YourModule"

# Project
rootItem: "/sitecore/templates/Project/YourProject"
```

### Add More Tests

Add new test at end of Phase 6:
```powershell
$query11 = @"
{
  # Your custom GraphQL query
}
"@

$result11 = Invoke-SitecoreGraphQL -Query $query11 -TestName "Your test description"
```

## 📚 Related Documentation

- **HELIX-RELATIONSHIP-DISCOVERY.md** - Helix navigation patterns
- **SCHEMA-FIX-COMPLETE.md** - GraphQL schema reference
- **SEARCH-SCHEMA-FIX.md** - ContentSearchResult schema
- **.github/copilot-instructions.md** - MCP tool usage patterns

## ✅ Success Criteria

Script succeeds if:
1. ✅ All 10+ tests pass (no GraphQL errors)
2. ✅ At least 1 item found in each category (if TestFeatures exists)
3. ✅ Helix relationship map shows correct structure
4. ✅ No schema mismatch errors
5. ✅ Complete item inventory generated

## 🎉 Expected Result

```
[SUCCESS] All tests passed! TestFeatures discovery complete.

Total Unique Items: X
- Templates: Y
- Renderings: Z
- Resolvers: N
- Content Items: M
```

If TestFeatures doesn't exist in your Sitecore instance, you'll see:
```
[SUCCESS] All tests passed! TestFeatures discovery complete.
Total Unique Items: 0
```

This is normal - create the TestFeatures module in Sitecore first, or modify the script to test an existing feature.
