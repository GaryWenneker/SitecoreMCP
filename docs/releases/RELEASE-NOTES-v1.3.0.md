# Release Notes - Sitecore MCP Server v1.3.0

**Release Date:** October 16, 2025  
**Publisher:** Gary Wenneker ([gary.wenneker.org](https://www.gary.wenneker.org))

## 🎉 What's New in v1.3.0

Version 1.3.0 introduces powerful new features for version control, navigation, and item statistics. This release focuses on expanding the capabilities for item management and historical data access.

---

## ✨ New Features

### 1. Version Support (Story 3.2) ✅
Complete support for Sitecore item versions across all relevant tools.

**Tools Updated:**
- `sitecore_get_item` - Now accepts `version` parameter
- `sitecore_get_children` - Now accepts `version` parameter  
- `sitecore_get_field_value` - Now accepts `version` parameter

**Benefits:**
- Access specific versions of items (version 1, 2, 3, etc.)
- Compare different versions
- Work with historical content
- Version-aware field retrieval

**Example:**
```typescript
// Get version 2 of an item
await sitecore.getItem("/sitecore/content/Home", "en", "master", 2);

// Get field from specific version
await sitecore.getFieldValue("/sitecore/content/Home", "Title", "en", "master", 1);
```

---

### 2. Parent Navigation (Story 3.3) ✅
Navigate up the item tree with new parent and ancestor tools.

**New Tools:**
- `sitecore_get_parent` - Get the immediate parent of an item
- `sitecore_get_ancestors` - Get all ancestors up to the root

**Benefits:**
- Easy upward navigation in the content tree
- Get complete breadcrumb path
- Understand item hierarchy
- Safety checks prevent infinite loops (max 50 ancestors)

**Example:**
```typescript
// Get parent item
const parent = await sitecore.getParent("/sitecore/content/Home/Article1");
// Returns: { name: "Home", path: "/sitecore/content/Home", ... }

// Get all ancestors
const ancestors = await sitecore.getAncestors("/sitecore/content/Home/Article1");
// Returns: [
//   { name: "Home", path: "/sitecore/content/Home" },
//   { name: "content", path: "/sitecore/content" },
//   { name: "sitecore", path: "/sitecore" }
// ]
```

**Response Format:**
```json
{
  "count": 3,
  "ancestors": [...],
  "breadcrumb": "sitecore > content > Home"
}
```

---

### 3. Version History ✅
Discover all versions of an item.

**New Tool:**
- `sitecore_get_item_versions` - Get all versions with metadata

**Benefits:**
- Track version history and evolution
- Identify latest version
- Support audits and compliance

**Example:**
```typescript
const versions = await sitecore.getItemVersions("/sitecore/content/Home", "en");
// Returns: { totalVersions: 5, versions: [...], latestVersion: 5 }
```

---

### 4. Item Statistics ✅
Retrieve created/updated timestamps and users.

**New Tool:**
- `sitecore_get_item_with_statistics` - Adds statistics inline fragment

**Benefits:**
- Auditing and compliance
- Better visibility into content lifecycle

**Example:**
```typescript
const stats = await sitecore.getItemWithStatistics("/sitecore/content/Home", "en");
// Returns: { created: "20211011T073530Z", createdBy: "sitecore\\admin", ... }
```

---

## 🧪 Testing

All new features are covered by unit and integration tests.

- ✅ Version retrieval tests
- ✅ Parent/ancestor navigation tests
- ✅ Statistics retrieval tests

---

## 🚀 Upgrade Notes

- No breaking changes
- All new parameters are optional
- Backwards compatible with v1.2.0

---

## 📦 Packaging

- Updated `package.json` with new scripts
- Rebuilt TypeScript
- Ready for VSIX packaging

---

## 🔗 Links

- GitHub: https://github.com/GaryWenneker/sitecore-mcp-server
- Issues: https://github.com/GaryWenneker/sitecore-mcp-server/issues
- Blog: https://www.gary.wenneker.org
- LinkedIn: https://www.linkedin.com/in/garywenneker/

---

**Version:** 1.3.0  
**Status:** ✅ READY
