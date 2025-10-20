# GraphQL Schema Complete Analysis

## Query Root Type - Available Operations

The introspection query shows that the `Query` type has the following main operations:

### 1. **item** - Item Query
Retrieve a specific Sitecore item via path, ID or GUID.

**Current implementation:** ✅ Fully implemented in `sitecore_get_item`

**Arguments:**
- `path`: String - Item path (e.g. `/sitecore/content/Home`)
- `id`: ID - Item ID
- `guid`: String - Item GUID
- `language`: String - Language version
- `version`: Int - Version number

**Return fields:**
- `id`, `name`, `displayName`, `path`
- `template { id, name }`
- `hasChildren`
- `children { results { ... } }` - Child items
- `field(name: String)` - Get single field
- `fields { name, value }` - All fields
- `url` - Item URL
- `parent { ... }` - Parent item

**Possible improvements:**
- [ ] Add version-specific queries
- [ ] Add multi-language support
- [ ] Add URL query support
- [ ] Add parent navigation

---

### 2. **search** - Search Operation
Search items with filters and predicates.

**Current implementation:** ⚠️ Basic search works, but limited filters

**Arguments:**
- `where`: ItemSearchFilter - Filter predicates
  - `path`: String - Path filter
  - `name`: String - Name filter
  - `template`: String - Template filter
  - `language`: String - Language filter
  - `AND`, `OR` - Combination filters
- `first`: Int - Number of results
- `after`: String - Pagination cursor
- `orderBy`: ItemSearchOrder - Sorting

**Available Predicates:**
```graphql
ItemSearchFilter {
  path: String
  path_contains: String
  path_starts_with: String
  name: String
  name_contains: String
  template: String
  template_in: [String]
  hasChildren: Boolean
  hasLayout: Boolean
  AND: [ItemSearchFilter]
  OR: [ItemSearchFilter]
}
```

**Improvement needed:**
- [ ] Implement all filter operators (_contains, _starts_with, _in)
- [ ] Pagination with cursors
- [ ] Sorting options
- [ ] Combination filters (AND/OR)

---

### 3. **layout** - Layout/Presentation Query
Retrieve presentation/layout information from items.

**Current implementation:** ❌ NOT IMPLEMENTED

**Arguments:**
- `path`: String - Item path
- `id`: ID - Item ID
- `language`: String - Language version
- `site`: String - Site context

**Return fields:**
- `item { ... }` - The item itself
- `placeholders` - Placeholder structure
  - `name`: String
  - `path`: String
  - `renderings` - Renderings in placeholder
    - `renderingName`: String
    - `dataSource`: String
    - `parameters`: JSON
    - `uid`: String
    - `componentName`: String

**TODO: Add new MCP tool:**
```typescript
{
  name: "sitecore_get_layout",
  description: "Get layout/presentation data for an item",
  inputSchema: {
    type: "object",
    properties: {
      path: { type: "string", description: "Item path" },
      id: { type: "string", description: "Item ID" },
      language: { type: "string", description: "Language" }
    }
  }
}
```

---

### 4. **site** - Site Configuration
Retrieve site configuration and context information.

**Current implementation:** ❌ NOT IMPLEMENTED

**Arguments:**
- `name`: String - Site name
- `hostName`: String - Hostname

**Return fields:**
- `name`: String
- `hostName`: String
- `rootPath`: String
- `startItem`: String
- `language`: String
- `database`: String

**TODO: Add new MCP tool:**
```typescript
{
  name: "sitecore_get_site",
  description: "Get site configuration information",
  inputSchema: {
    type: "object",
    properties: {
      name: { type: "string", description: "Site name" },
      hostName: { type: "string", description: "Hostname" }
    }
  }
}
```

---

## Object Types - Important Schema Types

The introspection reveals a huge number of custom types. The most important base types:

### ItemInterface
Base interface for all Sitecore items with standard fields.

### Template Types
All types starting with `_` are template-specific types (e.g. `_HomePage`, `_NewsArticle`).

Each has its own field set based on the template fields in Sitecore.

---

## Recommendations for MCP Extension

### Priority 1: Layout/Presentation Support ⭐⭐⭐
**Impact:** High - Essential for developers working with renderings/components
**Effort:** Medium

**Implementation:**
1. New tool: `sitecore_get_layout`
2. Query layout data for items
3. Return placeholder + rendering structure

### Priority 2: Enhanced Search ⭐⭐
**Impact:** Medium - Better query capabilities
**Effort:** Medium

**Improvements:**
1. All filter operators (_contains, _in, etc.)
2. Pagination with cursors
3. Sorting
4. Combination filters (AND/OR)

### Priority 3: Site Context ⭐
**Impact:** Low - Useful but not critical
**Effort:** Low

**Implementation:**
1. New tool: `sitecore_get_site`
2. Query site config
3. Return site properties

### Priority 4: Advanced Item Queries ⭐
**Impact:** Low - Edge cases
**Effort:** Low

**Improvements:**
1. Multi-language support
2. Version-specific queries
3. Parent navigation
4. URL-based queries

---

## Template Types - Dynamic Field Access

The schema contains **hundreds** of template-specific types (all types starting with `_`).

**Problem:** It's not practical to create a separate tool for each template type.

**Solution:** The existing `sitecore_get_field_value` tool can already retrieve **ALL** template fields via:

```graphql
{
  item(path: $path) {
    field(name: $fieldName) {
      name
      value
    }
  }
}
```

This works for **all** template types because it uses the generic `field(name:)` accessor.

**Recommendation:** Document that `sitecore_get_field_value` works for ALL template fields, regardless of template type.

---

## Input Types - Available Filters

The most important input types for filtering:

### ItemSearchFilter
```graphql
{
  path: String
  path_contains: String
  path_starts_with: String
  name: String
  name_contains: String
  template: String
  template_in: [String]
  hasChildren: Boolean
  hasLayout: Boolean
  AND: [ItemSearchFilter]
  OR: [ItemSearchFilter]
}
```

### ItemSearchOrder
```graphql
{
  name: ASC | DESC
  displayName: ASC | DESC
  path: ASC | DESC
  created: ASC | DESC
  updated: ASC | DESC
}
```

---

## Conclusion & Action Plan

### Current Status
✅ Item queries - **complete**
✅ Children queries - **complete**
✅ Field value queries - **complete for all templates**
✅ Basic search - **working**
⚠️ Advanced search - **limited**
❌ Layout queries - **missing**
❌ Site queries - **missing**

### Recommended Extensions

#### Must Have (Priority 1)
1. **Layout/Presentation tool** - New `sitecore_get_layout` tool
2. **Enhanced search filters** - Full filter operator support

#### Nice to Have (Priority 2-3)
3. **Site configuration tool** - New `sitecore_get_site` tool
4. **Multi-language support** - Add language parameter to existing tools
5. **Pagination support** - Cursor-based pagination for search

#### Low Priority (Priority 4)
6. **Version queries** - Version-specific queries
7. **Parent navigation** - Parent item traversal
8. **URL-based queries** - Query by URL path

---

## GraphQL Query Examples

### Layout Query Example
```graphql
{
  layout(path: "/sitecore/content/Home") {
    item {
      id
      name
      path
    }
    placeholders {
      name
      path
      renderings {
        renderingName
        componentName
        dataSource
        parameters
      }
    }
  }
}
```

### Site Query Example
```graphql
{
  site(name: "website") {
    name
    hostName
    rootPath
    startItem
    language
    database
  }
}
```

### Advanced Search Example
```graphql
{
  search(
    where: {
      AND: [
        { path_starts_with: "/sitecore/content" }
        { template_in: ["Template1", "Template2"] }
        { hasLayout: true }
      ]
    }
    orderBy: { updated: DESC }
    first: 10
  ) {
    results {
      id
      name
      path
      template { name }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```
