# CRITICAL: Schema Migration Required - Search API Changed

**Date**: October 16, 2025  
**Status**: 🚨 BREAKING CHANGES FOUND  
**Priority**: HIGH

---

## 🚨 Problem Summary

The `/items/master` schema has **COMPLETELY DIFFERENT** search API than `/edge`. The current code uses old `/edge` syntax which doesn't work.

### Current Issues

1. ❌ `executeQuery()` - Uses old `where: { name, value, operator }` syntax (BROKEN)
2. ❌ `searchItems()` - Same old syntax (BROKEN)  
3. ✅ `getChildren()` - Fixed in v1.2.1 (WORKING)
4. ✅ `getItem()`, `getFieldValue()`, `getTemplate()` - Never used search (WORKING)

---

## 📊 Schema Test Results

Ran `test-schema-validation.ps1`:

### ✅ PASSING (7/8):
1. ✅ `item()` → Direct Item object
2. ✅ `item().children()` → Direct [Item] array
3. ✅ `item().field()` → Direct string
4. ✅ `item().fields()` → [ItemField] array
5. ✅ `item().template` → Direct Template object
6. ✅ Endpoint `/items/master` → Correct
7. ✅ `children(first: N)` → Pagination works

### ❌ FAILING (1/8):
8. ❌ `search()` → Uses wrong syntax

---

## 🔍 Correct /items/master Search Schema

### Search Arguments
```graphql
search(
  first: Int                              # Limit results
  after: String                           # Cursor (default: "0")
  rootItem: String                        # Path/ID to search under
  keyword: String                         # Keyword search
  fieldsEqual: [ItemSearchFieldQuery]     # Field equality
  fieldsContain: [ItemSearchFieldQuery]   # Field contains
  language: String                        # Language filter
  # Many more filters...
)
```

### Return Type Structure
```graphql
type ContentSearchResults {
  results: ContentSearchResultConnection!  # Main results
  facets: [FacetResult]                   # Search facets
  totalCount: Int!                        # Total matches
}

type ContentSearchResultConnection {
  items: [SearchResultItem]!  # ⚠️ Items array (not direct!)
  pageInfo: PageInfo          # Pagination info
}

type SearchResultItem {
  item: Item!                 # ⚠️ Wrapped in 'item'!
}
```

### Correct Query Example
```graphql
query {
  search(
    keyword: "home"
    rootItem: "/sitecore/content"
    first: 10
  ) {
    results {
      items {              # ⚠️ Access via .items
        item {             # ⚠️ Then via .item
          id
          name
          path
        }
      }
    }
    totalCount
  }
}
```

### Access Pattern
```typescript
// ❌ OLD (doesn't work):
const items = result.search.results;

// ✅ NEW (correct):
const items = result.search.results.items.map(i => i.item);
```

---

## 🛠️ Required Code Changes

### Priority 1: Disable Broken Tools

Until search is fixed, these tools will return errors:
- `sitecore_query` (uses executeQuery)
- `sitecore_search` (uses searchItems)

**Recommendation**: Add try/catch with clear error message:
```typescript
throw new Error(
  "Search API migration in progress. " +
  "This tool currently doesn't work with /items/master schema. " +
  "Use sitecore_get_item or sitecore_get_children instead."
);
```

### Priority 2: Fix Search Methods

#### File: `src/sitecore-service.ts`

**Method 1: `executeQuery()` (line ~200)**
```typescript
// Current (BROKEN):
search(
  where: { name: "_path", value: $path, operator: CONTAINS }
  first: $first
  language: $language
) {
  results { id name }  // ❌ Wrong structure
}

// Should be:
search(
  rootItem: $path
  first: $first
  language: $language
) {
  results {
    items {           // ✅ Correct structure
      item {
        id
        name
        displayName
        path
        template { id name }
      }
    }
  }
  totalCount
}
```

**Method 2: `searchItems()` (line ~270)**
```typescript
// Current (BROKEN):
search(
  where: { name: "_name", value: $searchText, operator: CONTAINS }
  first: $first
) {
  results { id name }  // ❌ Wrong structure
}

// Should be:
search(
  keyword: $searchText
  rootItem: $rootPath
  first: $first
) {
  results {
    items {           // ✅ Correct structure
      item {
        id
        name
        path
      }
    }
  }
  totalCount
}
```

---

## ⚠️ Impact Assessment

### Tools Currently Broken
1. ❌ `sitecore_query` - Query execution (uses search)
2. ❌ `sitecore_search` - Search items (uses search)
3. ❌ `sitecore_command` - Natural language "search" commands

### Tools Still Working
1. ✅ `sitecore_get_item` - Get single item
2. ✅ `sitecore_get_children` - Get children (fixed v1.2.1)
3. ✅ `sitecore_get_field_value` - Get field value
4. ✅ `sitecore_get_template` - Get template info
5. ✅ `sitecore_scan_schema` - Schema scanning (if introspection works)

### User Impact
- **Low**: Most common operations (get item, children, fields) still work
- **Medium**: Search functionality is broken
- **Workaround**: Use `get_children` recursively or manually

---

## 📝 Action Items

### Immediate (This Session)
- [x] Document schema differences
- [x] Create SCHEMA-REFERENCE.md with correct patterns
- [x] Update copilot-instructions.md
- [x] Remove all /edge references
- [ ] Add error messages to broken search tools
- [ ] Update documentation (README, etc.)

### Next Session
- [ ] Rewrite `executeQuery()` with new search syntax
- [ ] Rewrite `searchItems()` with new search syntax
- [ ] Test all search scenarios
- [ ] Update natural language parser for search commands
- [ ] Full regression testing

### Future
- [ ] Add advanced search filters (fieldsEqual, fieldsContain)
- [ ] Add facet support
- [ ] Add search result highlighting
- [ ] Performance optimization

---

## 🎯 Workarounds for Users

Until search is fixed:

### Instead of Search:
```typescript
// ❌ Broken:
/sitecore search articles

// ✅ Use:
/sitecore get children /sitecore/content
// Then manually filter results
```

### Instead of Query:
```typescript
// ❌ Broken:
/sitecore query /sitecore/content//*[@@templatename='Article']

// ✅ Use:
/sitecore get children /sitecore/content
// Then check template names manually
```

---

## 📚 References

- **SCHEMA-REFERENCE.md** - Complete schema documentation
- **SCHEMA-FIX-CHILDREN.md** - Children fix (v1.2.1)
- **test-schema-validation.ps1** - Schema validation tests
- **graphql-schema-full.json** - Full schema JSON (217 MB)

---

**Status**: Documentation complete, code fixes pending  
**Version**: 1.2.1 (search broken), next 1.3.0 (search fixed)  
**Priority**: HIGH - Search is core functionality
