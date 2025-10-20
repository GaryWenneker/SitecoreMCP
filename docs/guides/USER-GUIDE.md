# Sitecore MCP Server - User Guide

**Version:** 1.5.0  
**Date:** October 17, 2025  
**Author:** Gary Wenneker

---

## 🎯 What is Sitecore MCP Server?

The **Sitecore MCP Server** is a Model Context Protocol (MCP) server that gives AI assistants like **Claude** and **GitHub Copilot** access to your Sitecore instance via GraphQL.

With this MCP you can:
- 🔍 Query and search Sitecore items
- 📊 Analyze content and discover relationships
- 🏗️ Explore Helix architecture
- 📄 Paginate through large datasets
- 🎯 Advanced filtering and sorting

---

## ✨ Features (v1.5.0)

### 🚀 Enterprise-Grade Search Suite

**1. Pagination Support**
- Cursor-based navigation with `pageInfo`
- Navigate large result sets efficiently
- Know if more results available (hasNextPage)

**2. Enhanced Search Filters (6 types)**
- `pathContains` - Find items by path substring
- `pathStartsWith` - Filter by path prefix
- `nameContains` - Search by item name
- `templateIn` - Filter by template IDs (OR logic)
- `hasChildrenFilter` - Find containers or leaf items
- `hasLayoutFilter` - Find renderable pages only

**3. Search Ordering**
- Multi-field sorting (name, displayName, path)
- ASC/DESC directions
- Chain multiple sort fields
- Locale-aware, case-insensitive

**4. Helix Relationship Discovery**
- Systematic search across 4 Helix paths
- Content → Template → Base Templates
- Page → Renderings → Data Sources
- Template → Content Items (reverse lookup)

---

## 📦 Installation

### Requirements
- Node.js 18+ 
- NPM 8+
- Access to a Sitecore instance with GraphQL API
- Sitecore API key with read permissions

### Steps

**1. Clone the Repository**
```bash
git clone https://github.com/GaryWenneker/sitecore-mcp-server.git
cd sitecore-mcp-server
```

**2. Install Dependencies**
```bash
npm install
```

**3. Build TypeScript**
```bash
npm run build
```

**4. Configure Environment Variables**

Create a `.env` file in the root:
```env
SITECORE_ENDPOINT=https://your-sitecore-instance/sitecore/api/graph/items/master
SITECORE_API_KEY=your-api-key-here
```

**⚠️ IMPORTANT:**
- Use ONLY `/sitecore/api/graph/items/master` endpoint
- `/sitecore/api/graph/edge` is NOT supported
- NEVER commit the `.env` file to Git (it's in `.gitignore`)

---

## 🔧 Configuration for AI Assistants

### Claude Desktop (macOS/Windows)

**1. Locate Claude Config File**
- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

**2. Add MCP Server**
```json
{
  "mcpServers": {
    "sitecore": {
      "command": "node",
      "args": [
        "C:\\path\\to\\sitecore-mcp-server\\dist\\index.js"
      ],
      "env": {
        "SITECORE_ENDPOINT": "https://your-instance/sitecore/api/graph/items/master",
        "SITECORE_API_KEY": "your-api-key"
      }
    }
  }
}
```

**3. Restart Claude Desktop**

**4. Verify MCP is Loaded**
- Look for 🔌 icon in Claude
- Should show "10 MCP tools available"

### GitHub Copilot (VS Code)

**1. Install Copilot Extension**
- Install "GitHub Copilot" extension in VS Code

**2. Configure MCP Settings**

Add to `.vscode/settings.json`:
```json
{
  "github.copilot.advanced": {
    "mcp": {
      "servers": {
        "sitecore": {
          "command": "node",
          "args": [
            "${workspaceFolder}/dist/index.js"
          ],
          "env": {
            "SITECORE_ENDPOINT": "https://your-instance/sitecore/api/graph/items/master",
            "SITECORE_API_KEY": "your-api-key"
          }
        }
      }
    }
  }
}
```

**3. Reload VS Code**

---

## 🎯 MCP Tools (10 Total)

### 1. sitecore_get_item
**Purpose:** Get a specific Sitecore item

**Parameters:**
- `path` (required) - Item path (e.g. `/sitecore/content/Home`)
- `language` (optional) - Language (default: `en`)
- `version` (optional) - Specific version number

**Example:**
```json
{
  "name": "sitecore_get_item",
  "arguments": {
    "path": "/sitecore/content/Home",
    "language": "en"
  }
}
```

**Response:**
```json
{
  "id": "{110D559F-DEA5-42EA-9C1C-8A5DF7E70EF9}",
  "name": "Home",
  "path": "/sitecore/content/Home",
  "template": {
    "id": "{...}",
    "name": "Sample Item"
  },
  "hasChildren": true,
  "version": 1,
  "versionCount": 3
}
```

---

### 2. sitecore_get_children
**Purpose:** Get child items

**Parameters:**
- `path` (required) - Parent item path
- `language` (optional) - Language (default: `en`)
- `maxItems` (optional) - Max results (default: 100)

**Example:**
```json
{
  "name": "sitecore_get_children",
  "arguments": {
    "path": "/sitecore/content",
    "language": "en",
    "maxItems": 50
  }
}
```

---

### 3. sitecore_get_field_value
**Purpose:** Get a specific field value

**Parameters:**
- `path` (required) - Item path
- `fieldName` (required) - Field name
- `language` (optional) - Language (default: `en`)

**Example:**
```json
{
  "name": "sitecore_get_field_value",
  "arguments": {
    "path": "/sitecore/content/Home",
    "fieldName": "Title",
    "language": "en"
  }
}
```

---

### 4. sitecore_get_item_fields
**Purpose:** Get ALL fields based on template

**Parameters:**
- `path` (required) - Item path
- `language` (optional) - Language (default: `en`)

**Example:**
```json
{
  "name": "sitecore_get_item_fields",
  "arguments": {
    "path": "/sitecore/content/Home",
    "language": "en"
  }
}
```

**Response:**
```json
{
  "totalFields": 42,
  "fields": [
    { "name": "Title", "value": "Welcome" },
    { "name": "Text", "value": "..." },
    { "name": "Image", "value": "..." }
  ]
}
```

---

### 5. sitecore_get_template
**Purpose:** Get template information

**Parameters:**
- `templateId` (required) - Template GUID
- `language` (optional) - Language (default: `en`)

**Example:**
```json
{
  "name": "sitecore_get_template",
  "arguments": {
    "templateId": "{76036F5E-CBCE-46D1-AF0A-4143F9B557AA}",
    "language": "en"
  }
}
```

**Response:**
```json
{
  "id": "{...}",
  "name": "Sample Item",
  "fields": [...],
  "baseTemplates": [...]
}
```

---

### 6. sitecore_get_templates
**Purpose:** Get all templates

**Parameters:**
- `language` (optional) - Language (default: `en`)
- `maxTemplates` (optional) - Max results (default: 200)

**Example:**
```json
{
  "name": "sitecore_get_templates",
  "arguments": {
    "language": "en",
    "maxTemplates": 100
  }
}
```

---

### 7. sitecore_search (Enhanced v1.5.0!)
**Purpose:** Search items with advanced filters and sorting

**Parameters:**
- `rootPath` (required) - Start search path
- `keyword` (optional) - Search keyword
- `language` (optional) - Language (default: `en`)
- `maxItems` (optional) - Max results (default: 100)

**NEW in v1.5.0 - Filters:**
- `pathContains` (optional) - Substring in path
- `pathStartsWith` (optional) - Path prefix
- `nameContains` (optional) - Substring in name
- `templateIn` (optional) - Array of template IDs
- `hasChildrenFilter` (optional) - Boolean
- `hasLayoutFilter` (optional) - Boolean

**NEW in v1.5.0 - Ordering:**
- `orderBy` (optional) - Array of sort objects
  - `field`: `"name"` | `"displayName"` | `"path"`
  - `direction`: `"ASC"` | `"DESC"`

**Example (Basic):**
```json
{
  "name": "sitecore_search",
  "arguments": {
    "rootPath": "/sitecore/content",
    "keyword": "article",
    "language": "en"
  }
}
```

**Example (Advanced - v1.5.0):**
```json
{
  "name": "sitecore_search",
  "arguments": {
    "rootPath": "/sitecore/content",
    "pathContains": "articles",
    "hasLayoutFilter": true,
    "templateIn": [
      "{ARTICLE-TEMPLATE-ID}",
      "{NEWS-TEMPLATE-ID}"
    ],
    "orderBy": [
      { "field": "path", "direction": "ASC" },
      { "field": "name", "direction": "ASC" }
    ],
    "language": "en",
    "maxItems": 50
  }
}
```

**Response:**
```json
[
  {
    "id": "{...}",
    "name": "Article 1",
    "path": "/sitecore/content/Articles/Article 1",
    "template": { "id": "{...}", "name": "Article" },
    "hasChildren": false,
    "hasLayout": true
  },
  ...
]
```

---

### 8. sitecore_search_paginated (NEW v1.5.0!)
**Purpose:** Paginated search with cursor navigation

**Parameters:**
- All parameters from `sitecore_search`
- `after` (optional) - Cursor for next page
- `before` (optional) - Cursor for previous page

**Example:**
```json
{
  "name": "sitecore_search_paginated",
  "arguments": {
    "rootPath": "/sitecore/content",
    "pathContains": "articles",
    "maxItems": 20,
    "after": null,
    "language": "en"
  }
}
```

**Response:**
```json
{
  "items": [...],
  "pageInfo": {
    "hasNextPage": true,
    "hasPreviousPage": false,
    "startCursor": "0",
    "endCursor": "19"
  },
  "totalCount": 156
}
```

**Next Page:**
```json
{
  "name": "sitecore_search_paginated",
  "arguments": {
    "rootPath": "/sitecore/content",
    "pathContains": "articles",
    "maxItems": 20,
    "after": "19",
    "language": "en"
  }
}
```

---

### 9. sitecore_query
**Purpose:** Execute custom GraphQL queries

**Parameters:**
- `query` (required) - GraphQL query string

**Example:**
```json
{
  "name": "sitecore_query",
  "arguments": {
    "query": "{ item(path: \"/sitecore/content/Home\", language: \"en\") { name path } }"
  }
}
```

---

### 10. sitecore_command
**Purpose:** Natural language interface (slash command)

**Parameters:**
- `command` (required) - Natural language command

**Examples:**
```json
{ "command": "get item /sitecore/content/Home" }
{ "command": "search articles" }
{ "command": "children of /sitecore/content" }
{ "command": "field Title from /sitecore/content/Home" }
{ "command": "templates" }
{ "command": "help" }
```

---

## 🎨 Using in AI Assistants

### Claude Desktop

**Natural Language:**
```
Get the Home item from Sitecore
```

Claude will automatically use `sitecore_get_item`.

**Direct Tool Call:**
```
Use sitecore_search to find all articles in /sitecore/content with layout
```

**Slash Command:**
```
/sitecore get item /sitecore/content/Home
```

### GitHub Copilot (VS Code)

**In Chat:**
```
@workspace Show me all articles from Sitecore
```

**In Code Comments:**
```typescript
// TODO: Fetch Home item from Sitecore and display title
```

Copilot will use the MCP tools to fetch Sitecore data.

---

## 🏗️ Helix Architecture Support

The MCP has full Helix awareness and can systematically discover relationships.

### The 4 Helix Search Paths

1. **`/sitecore/content`** - Content items (can be multilingual)
2. **`/sitecore/layout`** - Renderings & layouts (always 'en')
3. **`/sitecore/system`** - Settings & configuration (always 'en')
4. **`/sitecore/templates`** - Template definitions (always 'en')

### Helix Layers

**Foundation Layer (Most Stable)**
- Basic frameworks and shared functionality
- CSS/theming, indexing, multi-site
- Templates: `/sitecore/templates/Foundation/*`

**Feature Layer (Business Features)**
- Concrete features (news, articles, search, navigation)
- NO dependencies between Feature modules
- Templates: `/sitecore/templates/Feature/*`

**Project Layer (Compositional)**
- Site-specific page types and layouts
- Brings all features together
- Templates: `/sitecore/templates/Project/*`

### Relationship Discovery Workflows

**Workflow 1: Find Articles and Templates**
```
1. Search content items (pathContains: 'articles')
2. Get template info for each item
3. Search template definitions
4. Build: Article → Template → Base Templates
```

**Workflow 2: Find Renderings on Home Page**
```
1. Get Home page
2. Parse Layout field
3. Search renderings in /sitecore/layout
4. Get data sources
5. Build: Page → Renderings → Data Sources
```

See `HELIX-RELATIONSHIP-DISCOVERY.md` for complete workflows.

---

## 🧪 Testing

### Run All Tests
```bash
npm test
```

### Test Scripts

**Regression Tests:**
```bash
.\test-comprehensive-v1.4.ps1    # 25/25 tests
```

**Feature Tests:**
```bash
.\test-pagination-mcp.ps1        # Pagination validation
.\test-filters-validation.ps1    # Filter validation
.\test-ordering-validation.ps1   # Ordering validation
```

**Release Verification:**
```bash
.\test-release-v1.5.0.ps1        # Complete v1.5.0 check
```

**Expected:** All tests should pass (43/43 = 100%)

---

## 📚 Documentation

### Core Documentation
- **README.md** - This file
- **INSTALLATION.md** - Multi-IDE setup guide
- **QUICK-REFERENCE.md** - Command reference

### Feature Guides (v1.5.0)
- **PAGINATION-COMPLETE.md** - Pagination guide
- **ENHANCED-FILTERS-COMPLETE.md** - Filter documentation
- **SEARCH-ORDERING-COMPLETE.md** - Sorting guide
- **HELIX-RELATIONSHIP-DISCOVERY.md** - Helix workflows

### Release Notes
- **RELEASE-NOTES-v1.5.0.md** - Version 1.5.0 details
- **READY-TO-SHIP-v1.5.0.md** - Production readiness
- **SUMMARY-v1.5.0.md** - Complete summary

### Developer Guides
- **copilot-instructions.md** - AI assistant guidelines
- **SITECORE-COMMAND-GUIDE.md** - Slash command reference

---

## 🔍 Examples

### Example 1: Find All Articles with Layout

```json
{
  "name": "sitecore_search",
  "arguments": {
    "rootPath": "/sitecore/content",
    "pathContains": "articles",
    "hasLayoutFilter": true,
    "orderBy": [
      { "field": "name", "direction": "ASC" }
    ],
    "language": "en"
  }
}
```

### Example 2: Paginated Search

```json
{
  "name": "sitecore_search_paginated",
  "arguments": {
    "rootPath": "/sitecore/content",
    "templateIn": ["{ARTICLE-ID}", "{NEWS-ID}"],
    "maxItems": 20,
    "orderBy": [
      { "field": "path", "direction": "ASC" }
    ],
    "language": "en"
  }
}
```

**Response has `pageInfo`:**
```json
{
  "items": [...],
  "pageInfo": {
    "hasNextPage": true,
    "endCursor": "19"
  },
  "totalCount": 156
}
```

**Next page:**
```json
{
  "after": "19",
  ...
}
```

### Example 3: Helix Template Discovery

```json
{
  "name": "sitecore_search",
  "arguments": {
    "rootPath": "/sitecore/templates/Feature",
    "language": "en"
  }
}
```

For each template:
```json
{
  "name": "sitecore_get_template",
  "arguments": {
    "templateId": "{TEMPLATE-ID}",
    "language": "en"
  }
}
```

Then search content:
```json
{
  "name": "sitecore_search",
  "arguments": {
    "rootPath": "/sitecore/content",
    "templateIn": ["{TEMPLATE-ID}"],
    "language": "en"
  }
}
```

---

## ⚡ Performance Tips

### 1. Use Appropriate maxItems
```json
// BAD: Fetching too many items
{ "maxItems": 10000 }

// GOOD: Realistic number
{ "maxItems": 100 }

// BEST: Use pagination
{ "maxItems": 20, "after": "cursor" }
```

### 2. Filter Early
```json
// BAD: Fetch everything, then filter
sitecore_search({ rootPath: "/sitecore" })

// GOOD: Filter directly
sitecore_search({ 
  rootPath: "/sitecore/content/Articles",
  hasLayoutFilter: true
})
```

### 3. Use pathStartsWith for Targeted Searches
```json
// BAD: Broad search
{ "rootPath": "/sitecore", "pathContains": "articles" }

// GOOD: Specific path
{ "rootPath": "/sitecore/content/MySite/Articles" }
```

---

## 🐛 Troubleshooting

### MCP Tools Not Visible

**Check:**
1. Is Claude/Copilot restarted?
2. Is the config file correct?
3. Is the path to `dist/index.js` correct?

**Test:**
```bash
node dist/index.js
# Should start MCP server without errors
```

### "Item Not Found" Errors

**Check language:**
```json
// Templates, layout, system: ALWAYS 'en'
{ "path": "/sitecore/templates/...", "language": "en" }

// Content: Can be multilingual
{ "path": "/sitecore/content/...", "language": "nl" }
```

### GraphQL Errors

**Check endpoint:**
```
✅ CORRECT: /sitecore/api/graph/items/master
❌ WRONG:    /sitecore/api/graph/edge
```

**Check API key:**
- Must have read permissions
- Is in environment variables

### Build Errors

**Run:**
```bash
npm run build
```

**Check for TypeScript errors.**

---

## 🔗 Links

**Repository:**
- GitHub: https://github.com/GaryWenneker/sitecore-mcp-server
- Issues: https://github.com/GaryWenneker/sitecore-mcp-server/issues

**Sitecore Helix:**
- Official Docs: https://helix.sitecore.com/
- Architecture Principles: https://helix.sitecore.com/principles/architecture-principles/

**Author:**
- Blog: https://www.gary.wenneker.org
- LinkedIn: https://www.linkedin.com/in/garywenneker/
- GitHub: https://github.com/GaryWenneker

---

## 📝 Changelog

### v1.5.0 (October 17, 2025)
- ✅ Pagination Support (cursor-based)
- ✅ Enhanced Search Filters (6 types)
- ✅ Search Ordering (multi-field)
- ✅ Helix Relationship Discovery (documentation)

### v1.4.1 (August 25, 2025)
- ✅ Runtime error fixes
- ✅ Schema validation improvements

### v1.4.0 (August 20, 2025)
- ✅ Smart language defaults
- ✅ Helix architecture awareness
- ✅ Template-based field discovery
- ✅ Version management

### v1.3.0 (August 15, 2025)
- ✅ Version control support
- ✅ Parent navigation
- ✅ Item statistics

---

## 📄 License

MIT License - See LICENSE file

---

## 👥 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**Version:** 1.5.0  
**Last Updated:** October 17, 2025  
**Author:** Gary Wenneker  
**Status:** ✅ Production Ready
