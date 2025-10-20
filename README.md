# Sitecore MCP Server

[![CI](https://github.com/GaryWenneker/SitecoreMCP/actions/workflows/ci.yml/badge.svg)](https://github.com/GaryWenneker/SitecoreMCP/actions/workflows/ci.yml)
[![Root Hygiene](https://github.com/GaryWenneker/SitecoreMCP/actions/workflows/root-scan.yml/badge.svg)](https://github.com/GaryWenneker/SitecoreMCP/actions/workflows/root-scan.yml)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.3-blue.svg)](https://www.typescriptlang.org/)
[![Code Style: Prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg)](https://prettier.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D18-brightgreen.svg)](https://nodejs.org/)

A Model Context Protocol (MCP) server for Sitecore with **GraphQL API**, **version control**, **parent navigation**, and **item statistics**. Query Sitecore items via AI assistants like Claude and GitHub Copilot.

## ✨ Features

### 🎯 Core Tools (21 total)

**Item Operations:**
- 🔍 **sitecore_get_item** - Get a specific Sitecore item (with version support)
- 👶 **sitecore_get_children** - Get child items (with version support)
- 📄 **sitecore_get_field_value** - Get a field value (with version support)
- � **sitecore_get_item_fields** - Get all fields of an item (template-aware)
- �🔎 **sitecore_query** - Execute Sitecore queries
- 🔍 **sitecore_search** - Search items with filters and ordering
- 📄 **sitecore_search_paginated** - Search with pagination support

**Template Operations:**
- 📋 **sitecore_get_template** - Get template information
- 📚 **sitecore_get_templates** - Get multiple templates

**Version Control:**
- 🕐 **sitecore_get_item_versions** - See all versions of an item
- 📊 **sitecore_get_item_with_statistics** - Get created/updated dates and users

**Navigation:**
- ⬆️ **sitecore_get_parent** - Navigate to parent item
- 🧭 **sitecore_get_ancestors** - Get all ancestors (breadcrumb)

**Layout & Sites:**
- 🎨 **sitecore_get_layout** - Get layout/presentation information
- 🌐 **sitecore_get_sites** - Get Sitecore site configurations

**Mutations (Create/Update/Delete):**
- ➕ **sitecore_create_item** - Create new Sitecore items
- ✏️ **sitecore_update_item** - Update existing items
- ❌ **sitecore_delete_item** - Delete items

**Advanced Features:**
- 🔬 **sitecore_scan_schema** - Automatic GraphQL schema analysis
- 💬 **sitecore_command** - Natural language `/sitecore` commands in chat
- 🔍 **sitecore_discover_item_dependencies** - Comprehensive item discovery with template, fields, and relationships

### 📣 Live progress (all tools)

All MCP tools now report progress via stderr so you can see what's happening during longer operations in your AI client.

- Format: `[tool_name] Message...`
- Examples:
  - `[sitecore_get_item] Starting (path=/sitecore/content/Home, language=nl-NL)`
  - `[sitecore_get_item] Completed: Home (template=Page, version=1)`
  - `[sitecore_search_paginated] Completed: 50 item(s), hasNextPage=true`

Note: We always mention the language in messages (critical for Sitecore).

### 🎨 Examples

**Via Slash Command Menu** (Type `/` in chat):
```bash
# 1. Type / to open the menu
# 2. Choose "🔧 /sitecore - Sitecore command interface"
# 3. Type your command (with or without /sitecore prefix)

help
get item /sitecore/content/Home
get item /sitecore/content/Home version 2    # NEW: Version support!
get parent /sitecore/content/Home/Article    # NEW: Parent navigation!
get ancestors /sitecore/content/Home/Article # NEW: Breadcrumb!
search articles
field Title from /sitecore/content/Home
templates
```

**Direct Natural Language Commands**:
```bash
/sitecore help
/sitecore scan schema
/sitecore get item /sitecore/content/Home
/sitecore get item /sitecore/content/Home version 2
/sitecore get parent /sitecore/content/Home/Article
/sitecore get ancestors /sitecore/content/Home/Article
/sitecore search articles
/sitecore field Title from /sitecore/content/Home
/sitecore templates
```

**Version Control Examples**:
```typescript
// Get specific version
sitecore_get_item({ 
  path: "/sitecore/content/Home", 
  language: "en",
  version: 2 
})

// Get all versions
sitecore_get_item_versions({
  path: "/sitecore/content/Home",
  language: "en"
})
// Returns: { totalVersions: 5, versions: [...], latestVersion: 5 }

// Get item with statistics
sitecore_get_item_with_statistics({
  path: "/sitecore/content/Home",
  language: "en"
})
// Returns: { created: "20211011T073530Z", createdBy: "sitecore\admin", ... }
```

**Navigation Examples**:
```typescript
// Get parent
sitecore_get_parent({
  path: "/sitecore/content/Home/Article"
})
// Returns: { name: "Home", path: "/sitecore/content/Home", ... }

// Get all ancestors (breadcrumb)
sitecore_get_ancestors({
  path: "/sitecore/content/Home/Article"
})
// Returns: { 
//   count: 3,
//   ancestors: [...],
//   breadcrumb: "sitecore > content > Home"
// }
```

## 📚 Docs Map

- **docs/guides/** - Technical guides and implementation details (GUID formats, content discovery, slash commands, etc.)
- **docs/releases/** - Release notes per version (RELEASE-NOTES-v1.x.md)
- **docs/ready-to-ship/** - Release checklists and readiness documents per version
- **docs/status/** - Progress reports and status updates
- **docs/summaries/** - Version summaries and overviews
- **docs/BACKLOG.md** - Product backlog and planning

Tip: All documentation is organized under docs/. Root contains only README.md.

## 📁 Repository Structuur

```
SitecoreMCP/
├── .github/                        # CI/CD workflows en GitHub configuratie
│   └── workflows/
│       └── root-scan.yml          # Root hygiene enforcement
│
├── src/                            # TypeScript source code
│   ├── index.ts                   # MCP server entry point (11 tools)
│   ├── sitecore-service.ts        # GraphQL client & business logic
│   ├── sitecore-types.ts          # TypeScript type definitions (auto-generated)
│   └── sitecore-types-FULL.ts     # Extended type definitions
│
├── dist/                           # Compiled JavaScript (build output)
│
├── scripts/                        # All scripts organized by category
│   ├── build/
│   │   └── build-vsix.ps1         # VS Code extension packaging
│   │
│   ├── schema/                     # GraphQL schema management
│   │   ├── download-schema.ps1    # Download schema from Sitecore
│   │   ├── download-full-schema.ps1
│   │   ├── analyze-schema.ps1     # Analyze schema structure
│   │   ├── extract-schema-types.ps1
│   │   ├── find-mutations.ps1     # Find mutation capabilities
│   │   ├── generate-types.ps1     # Generate TypeScript types
│   │   ├── generate-types-full.ps1
│   │   └── check-search-schema.cjs # Validate search schema
│   │
│   ├── tests/                      # Test scripts (72 files)
│   │   ├── Load-DotEnv.ps1        # Environment loader for tests
│   │   ├── test-*.ps1             # PowerShell test scripts
│   │   └── test-*.cjs             # Node.js test scripts
│   │
│   ├── tools/                      # Utility tools
│   │   ├── build-relationship-graph.ps1  # Build item relationship graphs
│   │   ├── parse-field-references.ps1    # Parse field references
│   │   └── Load-DotEnv.ps1              # Canonical environment loader
│   │
│   └── wrappers/                   # Backward compatibility wrappers
│       ├── *.ps1                  # PowerShell wrappers (deprecated)
│       └── *.cjs                  # Node.js wrappers (deprecated)
│
├── docs/                           # All documentation
│   ├── guides/                    # Technical guides (35+ documents)
│   ├── releases/                  # Release notes per version
│   ├── ready-to-ship/             # Release readiness checklists
│   ├── status/                    # Status and progress reports
│   ├── summaries/                 # Version summaries
│   └── BACKLOG.md                # Product backlog
│
├── data/                          # Schema and graph data (generated)
│   ├── graphql-schema.json       # GraphQL schema dump
│   ├── graphql-schema-full.json  # Full introspection result
│   └── graph.json                # Relationship graph data
│
├── .env.example                   # Environment variabelen template
├── package.json                   # NPM dependencies en scripts
├── tsconfig.json                  # TypeScript compiler configuratie
├── LICENSE                        # MIT licentie
└── README.md                      # Dit bestand (quick start)
```

### Purpose per Directory

| Directory | Purpose | Allowed Files |
|-----------|---------|---------------|
| **Root** | Project metadata and entry point | Config files + README.md only |
| **src/** | TypeScript source code | .ts files |
| **dist/** | Build output | .js, .d.ts files (generated) |
| **scripts/** | All scripts organized | Subdirectories per category |
| **scripts/build/** | Build and packaging scripts | build-vsix.ps1 |
| **scripts/schema/** | GraphQL schema management | Schema tools (9 scripts) |
| **scripts/tests/** | Test scripts | Test files (72 files) |
| **scripts/tools/** | Utility tools | Helpers and utilities (3 tools) |
| **scripts/wrappers/** | Backward compatibility | Deprecated wrappers (11 files) |
| **docs/** | All documentation | .md files in subdirectories |
| **data/** | Generated data files | .json schema dumps (gitignored) |
| **.github/** | CI/CD workflows | GitHub Actions workflows |

**Hygiene Policy**: Root contains ONLY config files and README.md. All documentation is under docs/, all scripts under scripts/. This structure is enforced by CI workflow (root-scan.yml).

## ✅ API Status

**GraphQL API is active and working!**
- ✅ Item queries
- ✅ Get children
- ✅ Get field values
- ✅ Template information
- ✅ Variables in queries

## Requirements

- Node.js 18 or higher
- Sitecore instance with GraphQL endpoint: `/sitecore/api/graph/items/master`
- Sitecore API Key (see configuration)

## 🚀 Quick Start

### 1. Install dependencies

```bash
cd c:\gary\Sitecore\SitecoreMCP
npm install
npm run build
```

### 2. Configure Environment

Copy `.env.example` to `.env` and configure your Sitecore instance:

```bash
SITECORE_HOST=https://your-sitecore-instance.com
SITECORE_API_KEY=your-api-key-here
```

### 3. Run Tests

Verify that all MCP tools are working correctly:

```powershell
.\scripts\tests\run-tests.ps1
```

This will run a comprehensive test suite covering:
- ✅ Basic queries (item retrieval, children, fields)
- ✅ Advanced search & discovery
- ✅ Navigation & hierarchy (parent, ancestors)
- ✅ Utilities & extensions

Expected output: **17/17 tests passed (100% success rate)**

### 4. Configure your IDE/Tool

Choose your favorite tool and configure the Sitecore MCP server:

**Claude Desktop**: `%APPDATA%\Claude\claude_desktop_config.json`
**VS Code**: `.vscode/settings.json` or User Settings  
**Rider**: `%APPDATA%\JetBrains\Rider2024.3\options\mcp-servers.json`  
**Visual Studio**: `%USERPROFILE%\.github-copilot\mcp-servers.json`

See [docs/guides/INSTALLATION.md](docs/guides/INSTALLATION.md) for detailed configuration per tool.

**Example configuration** (Claude Desktop):

```json
{
  "mcpServers": {
    "sitecore": {
      "command": "node",
      "args": ["c:\\gary\\Sitecore\\SitecoreMCP\\dist\\index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

For VS Code, Rider and Visual Studio configurations, see [docs/guides/INSTALLATION.md](docs/guides/INSTALLATION.md).

### 5. Restart your tool

- **Claude Desktop**: Close completely and restart
- **VS Code**: Reload Window (Ctrl+Shift+P)
- **Rider**: Invalidate Caches & Restart
- **Visual Studio**: Close solution and reopen

The Sitecore MCP server should now be available!

## 💡 Gebruik Voorbeelden

### Slash Command Menu (New in v1.2.0!)

**Step 1**: Open your AI chat (Claude Desktop, VS Code Copilot, etc.)  
**Step 2**: Type `/` to open the slash command menu  
**Step 3**: Choose `🔧 /sitecore` from the menu  
**Step 4**: Type your command (prefix is automatically added)

```bash
# Via slash menu:
/ → choose /sitecore → "help"
/ → choose /sitecore → "get item /sitecore/content/Home"
/ → choose /sitecore → "search articles"
/ → choose /sitecore → "field Title from /sitecore/content/Home"
```

### Direct Commands

You can also type direct commands:

```
Get the Home item: /sitecore/content/Home
```

```
Show all children of /sitecore/content/Home
```

```
Execute this query: /sitecore/content/Home//*[@@templatename='Sample Item']
```

```
Search for items with "contact" in the name
```

```
What is the Title field of /sitecore/content/Home?
```

See [docs/guides/EXAMPLES.md](docs/guides/EXAMPLES.md) and [docs/guides/SLASH-COMMAND.md](docs/guides/SLASH-COMMAND.md) for more extensive examples.

## Sitecore PowerShell Extensions API

This MCP server uses the Sitecore PowerShell Extensions (SPE) API endpoint:

```
POST https://your-sitecore-instance.com/sitecore/api/spe/v2/script
```

Ensure SPE is correctly configured and the API is accessible.

## 📚 Documentation

For a complete overview of all directories and their purposes, see the **📁 Repository Structure** section above.

**Main documents:**
- **[README.md](README.md)** (this file): Overview and quick start
- **[docs/guides/INSTALLATION.md](docs/guides/INSTALLATION.md)**: Detailed installation for all IDEs
- **[docs/guides/EXAMPLES.md](docs/guides/EXAMPLES.md)**: Extensive usage examples and use cases
- **[docs/guides/SLASH-COMMAND.md](docs/guides/SLASH-COMMAND.md)**: ⚡ Slash command menu guide
- **[docs/guides/SITECORE-COMMAND-GUIDE.md](docs/guides/SITECORE-COMMAND-GUIDE.md)**: Natural language command reference

**Documentation Structure:**
- `docs/guides/` – Technical guides and how-to's (35+ documents)
- `docs/releases/` – Release notes per version (RELEASE-NOTES-v1.x.md)
- `docs/ready-to-ship/` – Release readiness checklists
- `docs/status/` – Status and progress reports
- `docs/summaries/` – Version summaries

**Note**: All documentation is under `docs/`. The root contains only README.md. Scripts are under `scripts/` in categories (build, schema, tests, tools, wrappers).

## 🔧 Troubleshooting

### MCP server doesn't appear
- **Claude**: Check `claude_desktop_config.json` syntax → Restart app
- **VS Code**: Reload Window (Ctrl+Shift+P) → Check Output panel
- **Rider**: Invalidate Caches → Check Event Log
- **Visual Studio**: Restart as Administrator → Check Extension logs

### SPE API errors
- Run `.\test-spe-api.ps1` to test the API
- Verify that SPE remoting is enabled in `Spe.config`
- Check Sitecore logs: `https://your-sitecore-instance.com/sitecore/admin/showlog.aspx`

### Items not found
- Verify that the path exists (case-sensitive!)
- Verify database (master/web/core)
- Check language code (en/nl/etc.)

For more details, see [docs/guides/INSTALLATION.md](docs/guides/INSTALLATION.md).

## ⚠️ Security

**Warning**: This configuration is intended for LOCAL development!

For production environments:
- ✅ Use HTTPS with valid certificate
- ✅ No credentials in configuration files
- ✅ Use Sitecore API keys
- ✅ Restrict SPE permissions
- ✅ Enable SSL certificate verification

## 🤝 Contributing

Suggestions and improvements are welcome! Create an issue or submit a pull request.

## 📄 License

MIT
