# Sitecore GraphQL Schema Reference - /items/master

**Endpoint**: `/sitecore/api/graph/items/master`  
**Date**: October 16, 2025  
**Version**: 1.2.1  
**Status**: ✅ PRODUCTION

---

## ⚠️ CRITICAL: Edge Schema Is REMOVED

**This MCP server ONLY supports `/sitecore/api/graph/items/master` schema.**

- ❌ `/sitecore/api/graph/edge` - **NOT SUPPORTED, REMOVED**
- ✅ `/sitecore/api/graph/items/master` - **PRIMARY ENDPOINT**
- ✅ `/sitecore/api/graph/items/web` - **ALTERNATIVE (published content)**

---

## 📋 Query Return Types Reference

### Item Queries

#### 1. `item()` - Single Item
**Returns**: `Item` (single object)

```graphql
query {
  item(path: "/sitecore/content/Home", language: "en") {
    id
    name
    displayName
    path
    template { id name }
    hasChildren
  }
}
```

**Response Structure**:
```json
{
  "data": {
    "item": {
      "id": "{...}",
      "name": "Home",
      ...
    }
  }
}
```

**Access in Code**: `result.item` (direct object)

---

#### 2. `item().children()` - Child Items
**Returns**: `[Item]` (direct array, NOT ItemSearchResults!)

```graphql
query {
  item(path: "/sitecore/content", language: "en") {
    children(first: 100) {    # ⚠️ Note: Direct array!
      id
      name
      displayName
      path
      template { id name }
      hasChildren
    }
  }
}
```

**Response Structure**:
```json
{
  "data": {
    "item": {
      "children": [           // ⚠️ Direct array!
        { "id": "{...}", "name": "Home", ... },
        { "id": "{...}", "name": "About", ... }
      ]
    }
  }
}
```

**Access in Code**: `result.item.children` (direct array)

**Arguments**:
- `first: Int` - Limit number of results (default: null = all)
- `after: String` - Cursor for pagination
- `requirePresentation: Boolean` - Only items with presentation
- `includeTemplateIDs: [String]` - Filter by template IDs
- `excludeTemplateIDs: [String]` - Exclude template IDs

---

#### 3. `item().field()` - Single Field Value
**Returns**: `String` (scalar value)

```graphql
query {
  item(path: "/sitecore/content/Home", language: "en") {
    field(name: "Title")      # ⚠️ Singular 'field', not 'fields'!
  }
}
```

**Response Structure**:
```json
{
  "data": {
    "item": {
      "field": "Home Title"   // ⚠️ Direct string value
    }
  }
}
```

**Access in Code**: `result.item.field` (direct string)

---

#### 4. `item().fields()` - Multiple Fields
**Returns**: `[ItemField]` (array of field objects)

```graphql
query {
  item(path: "/sitecore/content/Home", language: "en") {
    fields(ownFields: false) {  # ⚠️ Plural 'fields'!
      name
      value
    }
  }
}
```

**Response Structure**:
```json
{
  "data": {
    "item": {
      "fields": [                // ⚠️ Array of objects
        { "name": "Title", "value": "Home" },
        { "name": "Text", "value": "Welcome..." }
      ]
    }
  }
}
```

**Access in Code**: `result.item.fields` (array)

---

#### 5. `item().template` - Template Info
**Returns**: `Template` (single object)

```graphql
query {
  item(path: "/sitecore/content/Home", language: "en") {
    template {
      id
      name
      baseTemplates { id name }
      fields { name type }
      sections { name }
    }
  }
}
```

**Response Structure**:
```json
{
  "data": {
    "item": {
      "template": {           // ⚠️ Single object
        "id": "{...}",
        "name": "Sample Item",
        "baseTemplates": [...],
        "fields": [...]
      }
    }
  }
}
```

**Access in Code**: `result.item.template` (direct object)

---

### Search Queries

#### 6. `search()` - Search Items
**Returns**: `ItemSearchResults` (with `results` array!)

```graphql
query {
  search(
    where: {
      name: "_path"
      value: "/sitecore/content"
      operator: CONTAINS
    }
    first: 100
    language: "en"
  ) {
    results {                 # ⚠️ Has 'results' wrapper!
      id
      name
      path
      template { id name }
    }
    total
    pageInfo { hasNextPage endCursor }
  }
}
```

**Response Structure**:
```json
{
  "data": {
    "search": {
      "results": [            // ⚠️ Results array!
        { "id": "{...}", "name": "Home", ... },
        { "id": "{...}", "name": "About", ... }
      ],
      "total": 2,
      "pageInfo": { ... }
    }
  }
}
```

**Access in Code**: `result.search.results` (array)

---

## 🎯 Quick Reference Table

| Query | Return Type | Array Wrapper | Access Pattern |
|-------|-------------|---------------|----------------|
| `item()` | `Item` | ❌ No | `result.item` |
| `item().children()` | `[Item]` | ❌ No | `result.item.children` |
| `item().field()` | `String` | ❌ No | `result.item.field` |
| `item().fields()` | `[ItemField]` | ❌ No | `result.item.fields` |
| `item().template` | `Template` | ❌ No | `result.item.template` |
| `search()` | `ItemSearchResults` | ✅ Yes (.results) | `result.search.results` |

---

## ⚠️ Common Mistakes

### ❌ WRONG: Assuming children has results
```typescript
// DON'T DO THIS!
const children = result.item.children.results; // ❌ Error: results doesn't exist
```

### ✅ CORRECT: Direct array access
```typescript
// DO THIS!
const children = result.item.children; // ✅ Direct array
```

---

### ❌ WRONG: Using fields (plural) for single field
```graphql
# DON'T DO THIS!
{
  item(path: "/path", language: "en") {
    fields(name: "Title")  # ❌ Error: fields doesn't accept 'name' argument
  }
}
```

### ✅ CORRECT: Use field (singular)
```graphql
# DO THIS!
{
  item(path: "/path", language: "en") {
    field(name: "Title")  # ✅ Correct
  }
}
```

---

### ❌ WRONG: Accessing search without results
```typescript
// DON'T DO THIS!
const items = result.search; // ❌ This is ItemSearchResults object, not array
```

### ✅ CORRECT: Access via results
```typescript
// DO THIS!
const items = result.search.results; // ✅ Array of items
```

---

## 📝 Code Patterns

### Pattern 1: Get Item with Fields
```typescript
const query = `
  query GetItem($path: String!, $language: String!) {
    item(path: $path, language: $language) {
      id
      name
      displayName
      fields(ownFields: false) {
        name
        value
      }
    }
  }
`;

const result = await executeGraphQL(query, { path, language });
const item = result.item; // Direct object
const fields = item.fields; // Direct array
```

### Pattern 2: Get Children
```typescript
const query = `
  query GetChildren($path: String!, $language: String!) {
    item(path: $path, language: $language) {
      children(first: 100) {
        id
        name
        path
      }
    }
  }
`;

const result = await executeGraphQL(query, { path, language });
const children = result.item.children; // Direct array (NO .results!)
```

### Pattern 3: Search Items
```typescript
const query = `
  query Search($value: String!, $first: Int!) {
    search(
      where: { name: "_name", value: $value, operator: CONTAINS }
      first: $first
    ) {
      results {
        id
        name
        path
      }
    }
  }
`;

const result = await executeGraphQL(query, { value, first });
const items = result.search.results; // Array via .results!
```

### Pattern 4: Get Single Field
```typescript
const query = `
  query GetField($path: String!, $language: String!, $fieldName: String!) {
    item(path: $path, language: $language) {
      field(name: $fieldName)
    }
  }
`;

const result = await executeGraphQL(query, { path, language, fieldName });
const value = result.item.field; // Direct string
```

---

## 🔍 Type Definitions

### Item Type
```typescript
type Item {
  id: String!
  name: String!
  displayName: String
  path: String!
  template: Template!
  hasChildren: Boolean!
  language: String!
  version: Int!
  
  // Field access
  field(name: String!): String
  fields(ownFields: Boolean): [ItemField]!
  
  // Navigation
  children(
    first: Int
    after: String
    requirePresentation: Boolean
    includeTemplateIDs: [String]
    excludeTemplateIDs: [String]
  ): [Item]!  // ⚠️ Direct array!
  
  parent: Item
  ancestors: [Item]!
}
```

### ItemSearchResults Type
```typescript
type ItemSearchResults {
  results: [Item]!      // ⚠️ Results wrapper!
  total: Int!
  pageInfo: PageInfo!
}
```

### Template Type
```typescript
type Template {
  id: String!
  name: String!
  baseTemplates: [Template]!
  fields: [TemplateField]!
  sections: [TemplateSection]!
}
```

### ItemField Type
```typescript
type ItemField {
  name: String!
  value: String
  type: String
}
```

---

## 🚀 Migration from /edge

If you have old code using `/edge` schema, here are the changes:

### Change 1: children query
```typescript
// ❌ OLD (/edge)
const children = result.item.children.results;

// ✅ NEW (/items/master)
const children = result.item.children;
```

### Change 2: Pagination argument
```graphql
# ❌ OLD (/edge)
children {
  results { id name }
}

# ✅ NEW (/items/master)
children(first: 100) {
  id name
}
```

### Change 3: Endpoint
```typescript
// ❌ OLD
const endpoint = "/sitecore/api/graph/edge";

// ✅ NEW
const endpoint = "/sitecore/api/graph/items/master";
```

---

## 📚 Related Documentation

- **README.md** - Project overview
- **SCHEMA-FIX-CHILDREN.md** - Children query fix details
- **PATCH-v1.2.1.md** - Version 1.2.1 release notes
- **copilot-instructions.md** - Copilot AI guidance

---

## ✅ Verification Checklist

When writing GraphQL queries, verify:

- [ ] Using `/items/master` endpoint (NOT `/edge`)
- [ ] `item().children` accessed as direct array (NO `.results`)
- [ ] `item().field()` for single field (singular)
- [ ] `item().fields()` for multiple fields (plural)
- [ ] `search().results` accessed via `.results` wrapper
- [ ] `children()` has `first` argument for pagination
- [ ] All queries tested in GraphQL UI first

---

**Last Updated**: October 16, 2025  
**Schema Version**: /items/master  
**MCP Server Version**: 1.2.1
