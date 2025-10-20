# Copilot Instructions - Sitecore MCP Server

## Project Context

Dit is een **Model Context Protocol (MCP) server** voor Sitecore integratie. Het project maakt het mogelijk om vanuit AI assistenten (Claude, GitHub Copilot, etc.) Sitecore items te bevragen via GraphQL.

## ⚠️ CRITICAL: SITECORE GUID FORMAT

**🎯 PRIMARY RULE: ALTIJD GUID FORMATTING TOEPASSEN!**

**HET PROBLEEM:**

## ⚠️ CRITICAL: REPO HYGIËNE – DOCS & SCRIPTS IN MAPPEN, NIET IN DE ROOT

**REGEL (verplicht):**
- Alle documentatiebestanden (.md) horen onder `docs/` in een passende submap (bijv. `docs/guides`, `docs/status`, `docs/releases`, `docs/ready-to-ship`, `docs/summaries`).
- Alle scripts (.ps1, .sh, .cjs, .js helpers) horen onder `scripts/` met duidelijke submappen (bijv. `scripts/build`, `scripts/schema`, `scripts/tests`, `scripts/tools`).
- In de repository root staan géén losse docs of scripts. Deze moeten worden verplaatst of verwijderd.

**SANITATION AFTER MOVE (verplicht):**
- Na het verplaatsen van een script of document: verwijder het oude bestand op de oorspronkelijke locatie (root of elders). Geen dubbele kopieën achterlaten.
- Voer na elke wijziging een root-scan uit: controleer of er nog `*.md` of `*.ps1` bestanden in de root staan die al onder `docs/` of `scripts/` bestaan. Verwijder de root-varianten direct (behalve `README.md`).
- Werk links en verwijzingen bij naar het nieuwe pad onder `docs/` of `scripts/` en verifieer dat ze geldig zijn.

**Toegestane bestanden in de root (whitelist):**
- Project metadata: `README.md`, `LICENSE`, `package.json`, `package-lock.json` (of lockfile), `tsconfig.json`, `.env.example`
- Source/output/directories: `src/`, `dist/`, `docs/`, `scripts/`, `.github/`

**Migratie-checklist (doen bij elk PR):**
1. Scan de root: geen `*.md` en geen `*.ps1` (behalve `README.md`).
2. Verplaats docs naar de juiste map onder `docs/` en update links.
3. Verplaats scripts naar `scripts/<categorie>/` en update verwijzingen in README/scripthandles.
4. Verwijder achtergebleven root-kopieën (géén stubs in de root achterlaten). Als tijdelijke forwarding wrappers nodig zijn, markeer ze als `[DEPRECATED]` en plan hun verwijdering in de eerstvolgende PR.
5. Voeg een korte changelogregel toe in de PR-beschrijving: “root opgeschoond: docs/scripts verplaatst”.

**Automatische review (aanbevolen):**
- Voeg een pad-regel toe aan je code review checklist: “Block PR als er nieuwe `.md` of `.ps1` in de root bijkomen”.
- Optioneel: zet een eenvoudige CI-check in die faalt wanneer `git ls-files` een `*.md` of `*.ps1` in de root vindt (exclusief `README.md`).

**MANDATORY CONVERSION:**
```typescript
// ❌ WRONG - GraphQL returns this format
const rawId = "CFFDFAFA317F4E5498988D16E6BB1E68";
const query = `{ item(path: "{${rawId}}", language: "en") }`;  // FAILS!

// ✅ CORRECT - Must convert to dashed format
function formatGuid(guid: string): string {
  let clean = guid.replace(/[{}]/g, '');
  if (clean.includes('-')) return `{${clean}}`;  // Already formatted
  
  // Add dashes: 8-4-4-4-12 format
  if (clean.length === 32) {
    return `{${clean.substring(0,8)}-${clean.substring(8,12)}-${clean.substring(12,16)}-${clean.substring(16,20)}-${clean.substring(20,32)}}`;
  }
  return `{${clean}}`;
}

const formattedId = formatGuid(rawId);  // {CFFDFAFA-317F-4E54-9898-8D16E6BB1E68}
const query = `{ item(path: "${formattedId}", language: "en") }`;  // WORKS!
```

**WAAR TOEPASSEN:**
- ✅ **Template IDs**: Altijd formatteren voor queries
- ✅ **Base Template IDs**: Van `__Base template` field
- ✅ **Parent IDs**: Van parent references
- ✅ **ANY GUID**: Voor elke item path query

**IN SITECORE-SERVICE.TS:**
```typescript
// Helper method already implemented
private formatGuid(guid: string): string { ... }

// Use everywhere:
const templateId = this.formatGuid(item.templateId);
const baseId = this.formatGuid(baseTemplateIdFromField);
```

**IN POWERSHELL TESTS:**
```powershell
# Convert 32-char GUID to dashed format
$rawId = "CFFDFAFA317F4E5498988D16E6BB1E68"
$formatted = "{$($rawId.Substring(0,8))-$($rawId.Substring(8,4))-$($rawId.Substring(12,4))-$($rawId.Substring(16,4))-$($rawId.Substring(20,12))}"
# Result: {CFFDFAFA-317F-4E54-9898-8D16E6BB1E68}
```

**CRITICAL CHECKS:**
- ⚠️ **ALTIJD** check GUID format VOORDAT je query uitvoert
- ⚠️ **NOOIT** raw GUID zonder dashes in path queries
- ⚠️ **ALTIJD** curly braces + dashes: `{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}`
- ⚠️ Test query in GraphQL UI als item niet gevonden wordt

**Zie:** test-complete-workflow.ps1 voor working example.

---

## ⚠️ CRITICAL: ALWAYS USE MCP TOOLS

**🎯 PRIMARY RULE: ALTIJD MCP TOOLS GEBRUIKEN!**

**WAAROM:**
- ✅ MCP tools hebben **fallback logic** voor GraphQL limitaties
- ✅ MCP tools zijn **getest en production-ready**
- ✅ MCP tools hebben **optimized queries**
- ✅ MCP tools handlen **errors gracefully**
- ❌ Raw GraphQL queries **falen vaak** (path queries, timeouts, null results)
- ❌ PowerShell scripts zijn **alleen voor testing/debugging**

**WANNEER MCP TOOLS GEBRUIKEN:**
- ✅ **ALTIJD** voor content item discovery
- ✅ **ALTIJD** voor field data ophalen
- ✅ **ALTIJD** voor item references volgen
- ✅ **ALTIJD** voor search operations
- ✅ **ALTIJD** voor template/rendering/resolver info
- ✅ **ALLE** production use cases

**WANNEER RAW GRAPHQL TOEGESTAAN:**
- ⚠️ **ALLEEN** in PowerShell test scripts
- ⚠️ **ALLEEN** voor debugging/analysis
- ⚠️ **ALLEEN** voor schema exploration
- ⚠️ **NOOIT** in MCP server code
- ⚠️ **NOOIT** in production workflows

**AVAILABLE MCP TOOLS:**
```javascript
// Item Operations
sitecore_get_item({ path, language })           // Get single item
sitecore_get_item_fields({ path, language })    // Get all fields
sitecore_get_children({ path, language })       // Get direct children

// Template Operations
sitecore_get_template({ path, language })       // Get template definition
sitecore_get_templates({ path, language })      // Get multiple templates

// Comprehensive Discovery (⭐ NEW in v1.6.0)
sitecore_discover_item_dependencies({
  path,                 // Content item path
  language,             // Content language (default: "nl-NL" for content; templates always 'en')
  includeRenderings,    // Include renderings (default: false, can be slow)
  includeResolvers      // Include resolvers (default: false, can be slow)
})  // Returns: item + template + inheritance + fields + renderings + resolvers

// Search Operations
sitecore_search({ 
  keyword, 
  rootItem, 
  language,
  first,              // pagination
  after               // cursor
})

// Layout Operations
sitecore_get_layout({ path, language })         // Get layout info
sitecore_get_site({ name })                     // Get site config

// Advanced
sitecore_query({ query })                       // Custom GraphQL (last resort)
sitecore_command({ command })                   // Natural language
```

**CRITICAL WORKFLOWS:**

**1. Content Item Discovery:**
```javascript
// ✅ CORRECT - Use MCP tools
const item = await sitecore_get_item({
  path: '/sitecore/content/.../MyItem',
  language: 'nl-NL'
});

const fields = await sitecore_get_item_fields({
  path: item.path,
  language: 'nl-NL'
});

// ❌ WRONG - Raw GraphQL
const query = `{ item(path: "...") { fields { ... } } }`;
```

**2. Field Reference Following:**
```javascript
// ✅ CORRECT - Parse + MCP tools
const refs = parseFieldReferences(fields);
for (const ref of refs.PathReferences) {
  const refItem = await sitecore_get_item({
    path: ref.Path,
    language: 'en'
  });
}

// ❌ WRONG - Nested GraphQL query
```

**3. Comprehensive Item Discovery (⭐ RECOMMENDED):**
```javascript
// ✅ BEST - Get ALL dependencies in one call
const discovery = await sitecore_discover_item_dependencies({
  path: '/sitecore/content/Site/Home/MyItem',
  language: 'nl-NL',
  includeRenderings: false,  // Set to true if needed (slower)
  includeResolvers: false     // Set to true if needed (slower)
});

// Returns complete graph:
// - discovery.item (content item)
// - discovery.template (template definition with fields)
// - discovery.templateInheritance (base templates chain)
// - discovery.fields (all 76+ fields)
// - discovery.renderings (associated renderings)
// - discovery.resolvers (GraphQL resolvers)
// - discovery.summary (counts and metadata)

// ❌ WRONG - Manual multi-step discovery
const item = await getItem(...);
const template = await getTemplate(...);
const baseTemplates = await getBaseTemplates(...);
// ... many more calls
```

**4. Template-Based Discovery:**
```javascript
// ✅ CORRECT - Search + filter
const results = await sitecore_search({
  keyword: '',
  rootItem: '/sitecore/content',
  language: 'nl-NL'
});
const items = results.filter(r => r.templateName === 'TestFeature');

// ❌ WRONG - Complex nested query
```

**Zie:** `CONTENT-DISCOVERY-STRATEGY.md` voor complete MCP tools workflows.

---

## ⚠️ CRITICAL: ALWAYS MENTION LANGUAGE/LOCALE

**🌍 PRIMARY RULE: ALTIJD LANGUAGE PARAMETER VERMELDEN!**

**WAAROM:**
- ✅ Sitecore is **multi-lingual** - elke query MOET language specificeren
- ✅ Content items bestaan in **verschillende talen** (`en`, `nl-NL`, `de-DE`, etc.)
- ✅ Zonder language krijg je **verkeerde of lege resultaten**
- ✅ Default language is **niet gegarandeerd** - altijd expliciet opgeven
- ❌ Queries zonder language zijn **incomplete en falen vaak**

**MANDATORY IN ALLE MCP TOOLS:**
```javascript
// ✅ CORRECT - Language altijd opgeven
sitecore_get_item({ 
  path: '/sitecore/content/Site/Home', 
  language: 'nl-NL'  // ⚠️ VERPLICHT!
});

sitecore_get_item_fields({ 
  path: '/sitecore/content/Site/Home/MyItem', 
  language: 'en'  // ⚠️ VERPLICHT!
});

sitecore_search({ 
  keyword: 'test',
  rootItem: '/sitecore/content',
  language: 'nl-NL'  // ⚠️ VERPLICHT!
});

// ❌ WRONG - Geen language parameter
sitecore_get_item({ path: '/sitecore/content/Site/Home' });  // FAILS!
```

**LANGUAGE RULES PER ITEM TYPE:**
```typescript
// Content items: Gebruik user's gevraagde language
if (path.startsWith('/sitecore/content')) {
  language = 'nl-NL';  // Of 'en', 'de-DE', etc. zoals gevraagd
}

// Templates: ALTIJD 'en'
if (path.startsWith('/sitecore/templates')) {
  language = 'en';  // Sitecore standaard
}

// Renderings: ALTIJD 'en'
if (path.startsWith('/sitecore/layout')) {
  language = 'en';  // Sitecore standaard
}

// System items: ALTIJD 'en'
if (path.startsWith('/sitecore/system')) {
  language = 'en';  // Sitecore standaard
}
```

**IN USER RESPONSES:**
```markdown
✅ CORRECT:
"Getting GaryTestFeature fields in nl-NL..."
"Found 5 items in Dutch (nl-NL)..."
"Template retrieved in English (en)..."

❌ WRONG:
"Getting GaryTestFeature fields..."  // Missing language!
"Found 5 items..."                    // Missing language!
```

**WHEN RESOLVING REFERENCES:**
```javascript
// ✅ CORRECT - Preserve language when following references
const item = await sitecore_get_item({ 
  path: '/sitecore/content/Site/Home/Item', 
  language: 'nl-NL' 
});

const fields = await sitecore_get_item_fields({ 
  path: item.path, 
  language: 'nl-NL'  // Same language!
});

// Parse references
const refs = parseFieldReferences(fields);

// Follow each reference with SAME language
for (const ref of refs.PathReferences) {
  const refItem = await sitecore_get_item({
    path: ref.Path,
    language: 'nl-NL'  // ⚠️ Keep same language!
  });
}
```

**CRITICAL: NEVER OMIT LANGUAGE!**
- ❌ NOOIT queries zonder language parameter
- ✅ ALTIJD expliciet language opgeven in elke MCP tool call
- ✅ ALTIJD language vermelden in user responses
- ✅ ALTIJD language preserveren bij reference following
- ✅ ALTIJD language documenteren in code comments

**Zie:** Section "Smart Language Defaults" hieronder voor defaults per item type.

---

## ⚠️ CRITICAL REQUIREMENTS (v1.5.0+)

### 1. Smart Language Defaults
**SITECORE BEST PRACTICE - ALTIJD VOLGEN:**

```typescript
// Templates, renderings, system items: ALTIJD 'en'
if (path.startsWith('/sitecore/templates')) language = 'en';
if (path.startsWith('/sitecore/layout')) language = 'en';
if (path.startsWith('/sitecore/system')) language = 'en';

// Content items: 'en' als default, tenzij expliciet opgegeven
if (path.startsWith('/sitecore/content')) language = language || 'en';
```

**WAAROM:**
- Templates en renderings zijn ALTIJD in 'en' (Sitecore standaard)
- Content kan meertalig zijn
- Zonder deze rule krijg je item not found errors

### 2. Helix Architecture Awareness

**HELIX LAYERS:**
```
/sitecore/templates/
  ├── Foundation/    # Basis templates (altijd 'en')
  ├── Feature/       # Feature templates (altijd 'en')
  └── Project/       # Project-specifieke templates (altijd 'en')

/sitecore/layout/
  ├── Renderings/
  │   ├── Foundation/
  │   ├── Feature/
  │   └── Project/
  └── Layouts/
```

**CRITICAL:**
- Alle templates MOETEN in 'en' language
- Content volgt site language settings
- Renderings zijn in 'en'
- Media Library vaak in 'en'

**RELATIONSHIP DISCOVERY:**
Wanneer gevraagd wordt naar relaties tussen content items en hun data:

**Rule 1: Bidirectional Template-Based Navigation (⚠️ CRITICAL!)**

**A. Content → Template → Related Content (Upward Navigation)**
- Content Item → Get Template → Extract Feature Name → Search Related Items
- Voorbeeld flow:
  1. `sitecore_get_item('/sitecore/content/MySite/TestItem')` 
  2. Extract template info: `item.template.path.split('/')[4]` → "TestFeatures"
  3. Search ALL content using same template:
     - `sitecore_search` with `templateName: "TestFeature Item"`
     - Find siblings and related content items
  4. Search feature definition locations:
     - `/sitecore/templates/Feature/TestFeatures` (template definitions)
     - `/sitecore/layout/Renderings/Feature/TestFeatures` (renderings)
     - `/sitecore/system/Modules/Layout Service/Rendering Contents Resolvers/Feature/TestFeatures` (resolvers)

**B. Template → Content (Downward Navigation)**
- Template → Get Template Details → Search All Content Using This Template
- Voorbeeld flow:
  1. `sitecore_get_template('/sitecore/templates/Feature/TestFeatures/TestFeature Item')`
  2. Extract template name: `"TestFeature Item"`
  3. Search ALL content items using this template:
     - `sitecore_search` with `templateName: "TestFeature Item"` in `/sitecore/content`
  4. Analyze content distribution and usage

**⚠️ CRITICAL RULE:**
- Bij **ELKE** content item discovery → ALTIJD template analyseren → Zoek gerelateerde content
- Bij **ELKE** template discovery → ALTIJD content zoeken → Vind alle instances
- **Bidirectioneel**: Content ↔ Template ↔ Content (both ways!)

**Zie:** `HELIX-RELATIONSHIP-DISCOVERY.md` en `BIDIRECTIONAL-TEMPLATE-DISCOVERY.md` voor complete workflow en voorbeelden.

**Rule 2: GraphQL Limitations - Use MCP Tools Instead**

**⚠️ CRITICAL GRAPHQL LIMITATIONS:**

**Path Query Issues:**
- ❌ Content items: `item(path: "/sitecore/content/.../Item")` → returns `null`
- ❌ Template folders: `item(path: "/sitecore/templates/Feature/Module")` → returns `null`
- ❌ Nested queries with fields → timeout (too much data)
- ❌ Search by keyword → 0 results voor content items

**✅ SOLUTION: Always Use MCP Tools**

**For Template/Rendering/Resolver Discovery:**
```javascript
// MCP tools handle nested navigation internally
const template = await sitecore_get_template({
  path: '/sitecore/templates/Feature/TestFeatures/TestFeature',
  language: 'en'
});

// Or use search
const results = await sitecore_search({
  keyword: 'TestFeature',
  rootItem: '/sitecore/templates',
  language: 'en'
});
```

**For Content Items:**
```javascript
// NEVER use raw GraphQL for content items!
// ✅ CORRECT:
const item = await sitecore_get_item({
  path: '/sitecore/content/Site/Home/MyItem',
  language: 'nl-NL'
});

const fields = await sitecore_get_item_fields({
  path: item.path,
  language: 'nl-NL'
});

// ❌ WRONG: Raw GraphQL will fail or timeout
```

**Raw GraphQL Nested Pattern (ONLY for PowerShell test scripts):**
```graphql
# ⚠️ ONLY USE IN TEST SCRIPTS, NOT IN MCP SERVER!
{
  item(path: "/sitecore/templates/Feature", language: "en") {
    children(first: 100) {
      id
      name
      path
      children(first: 100) {  # Nested navigation
        id
        name
        path
        template { name }
      }
    }
  }
}
```

**Zie:** `PATH-QUERY-LIMITATION.md`, `CONTENT-DISCOVERY-STRATEGY.md` voor details.

**Rule 3: Use MCP Search for Multiple Relationships**

**✅ ALWAYS Use MCP sitecore_search:**
```javascript
// Recursief, met filters, sorting, pagination
const results = await sitecore_search({
  keyword: 'TestFeature',           // Search term
  rootItem: '/sitecore/content',    // Start location
  language: 'nl-NL',                // Language filter
  first: 100,                       // Pagination
  after: 'cursor'                   // Cursor for next page
});

// Filter results by template
const items = results.filter(r => r.templateName === 'TestFeature');
```

**❌ NEVER Use sitecore_get_children for deep discovery:**
- `sitecore_get_children` → alleen direct children (1 level)
- `sitecore_search` → ALL items recursief in subfolders
- Search heeft filters, sorting, pagination
- Search is optimized voor performance

**Helix Search Paths (via MCP tools):**
1. **Content**: `sitecore_search({ rootItem: '/sitecore/content', language: 'nl-NL' })`
2. **Templates**: `sitecore_get_template({ path: '/sitecore/templates/[Layer]/[Module]' })`
3. **Renderings**: `sitecore_search({ rootItem: '/sitecore/layout/Renderings/[Layer]' })`
4. **Resolvers**: `sitecore_search({ rootItem: '/sitecore/system/Modules/Layout Service' })`

**Zie:** `HELIX-RELATIONSHIP-DISCOVERY.md` en `CONTENT-DISCOVERY-STRATEGY.md`.

### 3. Version Management
**ALTIJD GEBRUIKEN:**
- Gebruik laatste versie tenzij expliciet anders gevraagd
- Response MOET altijd `versionCount` bevatten
- Format: `{ version: 2, versionCount: 5 }` = "versie 2 van 5"

### 4. Field Discovery via MCP Tools
**⚠️ ALWAYS Use sitecore_get_item_fields:**

```javascript
// ✅ CORRECT - MCP tool
const result = await sitecore_get_item_fields({
  path: '/sitecore/content/Site/Home/MyItem',
  language: 'nl-NL'
});

// Returns: { totalFields: 42, fields: [{name, value}] }
// Includes ALL fields (own + inherited)
```

**❌ NEVER Use Raw GraphQL Field Queries:**
```graphql
# ❌ WRONG - Individual field queries
{ item(path: "...") { 
    field(name: "Title") 
    field(name: "Text")
  }
}

# ❌ WRONG - Nested fields query (timeouts!)
{ item(path: "...") { 
    fields { name value }
  }
}
```

**Features van sitecore_get_item_fields:**
- ✅ Haalt ALLE fields in één call
- ✅ Includes inherited fields (Helix base templates)
- ✅ Optimized query (geen timeout)
- ✅ Fallback logic voor errors
- ✅ Returns structured data: `{ totalFields, fields }`

### 5. GraphQL Schema Awareness
**GEBRUIK .github/introspectionSchema.json:**
- ✅ **AUTHORITATIVE SCHEMA**: 15,687 lines volledig GraphQL schema
- ✅ Parse schema voor type definitions
- ✅ Extract return types per query  
- ✅ Generate TypeScript interfaces via `generate-types.ps1`
- ✅ Fix test failures door schema te checken
- ✅ Output: `src/sitecore-types.ts` (469 lines)

**CRITICAL TYPE DEFINITIONS:**
```typescript
// src/sitecore-types.ts (AUTO-GENERATED)
export interface Item {
  id: ID;
  name: string;
  path: string;
  template?: ItemTemplate;
  language?: ItemLanguage;
  version?: Int;
  hasChildren?: boolean;
  children?: Item[];
  parent?: Item;
  fields?: ItemField[];
}

export interface ContentSearchResults {
  total?: number;
  results?: ContentSearchResultConnection; // HAS items wrapper!
}

export interface TextField {
  value?: string; // CRITICAL: Always use { value }
}

export interface DateField {
  value?: string; // CRITICAL: Always use { value }
}
```

**REGENERATE TYPES:**
```powershell
.\generate-types.ps1
# Output: src/sitecore-types.ts
# 469 lines, all core types
```

## Belangrijke Configuratie Details

### Publisher Informatie
- **Publisher**: Gary Wenneker
- **Username**: GaryWenneker
- **Blog**: https://www.gary.wenneker.org
- **LinkedIn**: https://www.linkedin.com/in/garywenneker/
- **GitHub**: https://github.com/GaryWenneker

### Sitecore Instance
- **Endpoint**: `/sitecore/api/graph/items/master` (ONLY THIS, /edge is REMOVED)
- **API Key**: Configured via environment variables (SITECORE_API_KEY)
- **GraphQL UI**: [your-instance]/sitecore/api/graph/items/master/ui
- **Introspection**: ❌ NIET ONDERSTEUND (geeft 500 errors)
- **Security**: All credentials must be in .env file (never commit!)

### ⚠️ CRITICAL: Schema Endpoint
**ALLEEN `/sitecore/api/graph/items/master` wordt ondersteund!**
- ❌ `/sitecore/api/graph/edge` - **VERWIJDERD, GEBRUIK NIET**
- ✅ `/sitecore/api/graph/items/master` - **PRIMAIRE ENDPOINT**
- ✅ `/sitecore/api/graph/items/web` - **ALTERNATIEF (gepubliceerd)**

### Project Structuur
```
/
├── src/
│   ├── index.ts              # MCP server met 10 tools
│   └── sitecore-service.ts   # GraphQL client
├── dist/                     # Build output
├── test-*.ps1               # PowerShell test scripts
├── package.json             # NPM configuratie
├── tsconfig.json            # TypeScript config
└── *.md                     # Documentatie (15+ bestanden)
```

## PowerShell Script Guidelines

### ⚠️ CRITICAL: Environment Variables Loading
**ALTIJD deze pattern gebruiken voor .env loading:**

```powershell
# Load environment variables from .env file
. "$PSScriptRoot\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\.env"
```

**WAAROM:**
- `$PSScriptRoot` zorgt voor correcte path resolution
- Load-DotEnv.ps1 bevat custom .env parser
- Environment variables MOETEN beschikbaar zijn voor GraphQL calls
- Zonder dit krijg je null reference errors in REST calls

**WAAR GEBRUIKEN:**
- ✅ Alle test-*.ps1 scripts
- ✅ Scripts die SITECORE_API_KEY nodig hebben
- ✅ Scripts die SITECORE_HOST gebruiken
- ✅ Scripts die GraphQL queries uitvoeren

**AFTER LOADING:**
```powershell
# Check if loaded
if (-not $env:SITECORE_API_KEY) {
    Write-Host "[ERROR] SITECORE_API_KEY not found" -ForegroundColor Red
    exit 1
}

# Use in headers
$headers = @{
    "sc_apikey" = $env:SITECORE_API_KEY
    "Content-Type" = "application/json"
}

# Build endpoint
$endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
```

### ❌ NOOIT Emoji's Gebruiken
PowerShell ondersteunt geen emoji's goed. Gebruik in plaats daarvan:

```powershell
# ❌ FOUT - Emoji's werken niet
Write-Host "✅ Success!" -ForegroundColor Green
Write-Host "❌ Failed!" -ForegroundColor Red

# ✅ CORRECT - Gebruik ASCII met kleuren
Write-Host "[OK] Success!" -ForegroundColor Green
Write-Host "[PASS] Test passed!" -ForegroundColor Green
Write-Host "[FAIL] Test failed!" -ForegroundColor Red
Write-Host "[WARN] Warning message" -ForegroundColor Yellow
Write-Host "[INFO] Information" -ForegroundColor Cyan
Write-Host "  - Item name" -ForegroundColor Gray
```

### PowerShell Test Script Pattern
```powershell
# Always use ASCII characters
Write-Host "=== Test Name ===" -ForegroundColor Cyan
Write-Host "Testing something..." -ForegroundColor Yellow

try {
    # Test code
    Write-Host ""
    Write-Host "[OK] Test SUCCESS!" -ForegroundColor Green
    Write-Host "Details: $someValue" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Test: PASSED" -ForegroundColor Green
} catch {
    Write-Host "Test: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}
```

## MCP Tools Status

### ✅ Volledig Werkend (6 tools)
1. `sitecore_get_item` - Item ophalen
2. `sitecore_get_children` - Children ophalen
3. `sitecore_get_field_value` - Field value ophalen
4. `sitecore_query` - Custom GraphQL query
5. `sitecore_search` - Items zoeken
6. `sitecore_get_template` - Template info ophalen

### ⚠️ Schema Verificatie Nodig (2 tools)
7. `sitecore_get_layout` - Code ready, schema onbekend
8. `sitecore_get_site` - Code ready, schema onbekend

### ❌ Introspection Vereist (2 tools)
9. `sitecore_scan_schema` - Werkt niet (server ondersteunt geen introspection)
10. `sitecore_command` - Natural language parser (werkt behalve "scan schema")

## GraphQL Schema Reference

### Schema Files
1. **`.github/introspectionSchema.json`** (PRIMARY - 15,687 lines)
   - ✅ Complete GraphQL schema via introspection
   - ✅ All types, queries, mutations
   - ✅ 1,934 total types
   - ✅ Query type, Mutation type, Subscription type
   - ✅ Item interface with 1,800+ implementations
   - 🎯 **USE THIS for type validation!**

2. **`src/sitecore-types.ts`** (GENERATED - 469 lines)
   - ✅ TypeScript interfaces from introspectionSchema
   - ✅ Auto-generated via `generate-types.ps1`
   - ✅ Item, Query, Mutation, Search types
   - ✅ Field types (TextField, DateField, etc.)
   - ✅ Helix types, MCP response types

3. **`graphql-schema-summary.json`** (SUMMARY - 111 lines)
   - ✅ Quick reference for query args
   - ✅ Lightweight alternative

### Type Generation
```powershell
# Regenerate TypeScript types from schema
.\generate-types.ps1

# Output: src/sitecore-types.ts
# - Item interface
# - ContentSearchResults (with results.items!)
# - Query/Mutation types
# - Field types (TextField, DateField, etc.)
# - Helix types
# - MCP response types
```

## GraphQL Schema Patterns (/items/master)

### ⚠️ CRITICAL: Return Type Differences

| Query | Return Type | Has .results? | Access Pattern |
|-------|-------------|---------------|----------------|
| `item()` | `Item` | ❌ No | `result.item` |
| `item().children()` | `[Item]` | ❌ No | `result.item.children` |
| `item().field()` | `String` | ❌ No | `result.item.field` |
| `item().fields()` | `[ItemField]` | ❌ No | `result.item.fields` |
| `search()` | `ContentSearchResults` | ✅ Yes | `result.search.results` |

### ⚠️ CRITICAL: Item vs ContentSearchResult Fields

**Item Type (from `item()` query):**
```typescript
{
  id, name, displayName, path,
  template: { id, name },
  hasChildren,
  fields: [{ name, value }]
}
```

**ContentSearchResult Type (from `search()` query):**
```typescript
{
  id, name, path,
  templateName,  // ❌ NOT template { id, name }
  uri,           // ❌ NOT url! (it's uri)
  language       // ❌ String! (NOT language { name })
  // ❌ NO: displayName, hasChildren, fields
}
```

**CRITICAL RULE:**
- `sitecore_get_item` → Returns Item → Has `displayName`, `template`, `hasChildren`, `fields`
- `sitecore_search` → Returns ContentSearchResult → Has `templateName` (string), NO displayName/hasChildren/fields

**CRITICAL SCHEMA DIFFERENCES:**
- ⚠️ ContentSearchResult uses `uri` (NOT `url`)
- ⚠️ ContentSearchResult `language` is String (NOT `language { name }`)
- ⚠️ Item uses `url` and `language: { name }` object

### Children Query (Direct Array!)
```graphql
{
  item(path: "/sitecore/content", language: "en") {
    children(first: 100) {  # ⚠️ Direct array, NO results wrapper!
      id
      name
      path
      hasChildren
    }
  }
}
```
**Access**: `result.item.children` (NOT `result.item.children.results`)

### Single Field
```graphql
{
  item(path: "/path", language: "en") {
    field(name: "Title")  # ⚠️ Singular: field, not fields!
  }
}
```
**Access**: `result.item.field` (direct string)

### Multiple Fields
```graphql
{
  item(path: "/path", language: "en") {
    fields(ownFields: false) {  # ⚠️ Plural: fields, not field!
      name
      value
    }
  }
}
```
**Access**: `result.item.fields` (array)

### Search Query (Has .results.items!)
```graphql
{
  search(
    keyword: "Home"
    first: 100
  ) {
    results {  # ⚠️ Search HAS results wrapper!
      items {  # ⚠️ Then items array!
        id
        name
        path
      }
    }
  }
}
```
**Access**: `result.search.results.items` (array, NOT just .results!)

## TypeScript Patterns

### GraphQL Query Execution
```typescript
private async executeGraphQL(query: string): Promise<any> {
  const response = await axios.post(
    this.endpoint,
    { query },
    {
      headers: { 'sc_apikey': this.apiKey },
      httpsAgent: new https.Agent({ rejectUnauthorized: false })
    }
  );
  
  if (response.data.errors) {
    throw new Error(JSON.stringify(response.data.errors));
  }
  
  return response.data.data;
}
```

### MCP Tool Handler
```typescript
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  
  switch (name) {
    case "sitecore_get_item": {
      const result = await sitecoreService.getItem(
        args.path as string,
        args.language as string
      );
      return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
    }
  }
});
```

## VSIX Packaging

### Vereisten
- `@vscode/vsce` package (in devDependencies)
- Publisher naam: **GaryWenneker**
- Repository links naar Gary's GitHub

### Commands
```bash
# Build TypeScript
npm run build

# Package VSIX
npm run package:vsix

# Output: sitecore-mcp-server-1.1.0.vsix
```

### VSIX Configuratie
Zie `package.json` voor publisher info en repository links.

## Backlog Management

### Altijd Bijwerken
Wanneer je taken toevoegt, verwijdert of voltooit:
1. Update `BACKLOG.md`
2. Gebruik MoSCoW prioritering (Must/Should/Could/Won't)
3. Voeg time estimates toe
4. Update sprint planning als nodig

### Backlog Structuur
```markdown
## 🔴 Prioriteit 1: Critical (Must Have)
### X.X Task Name
**Story:** Als <role> wil ik <actie> zodat <doel>.
**Tasks:**
- [ ] Task 1
- [ ] Task 2
**Acceptatie Criteria:**
- Criteria 1
**Estimate:** X uur
**Dependencies:** Tool Y
```

## Testing

### Test Files
- `test-graphql-api.ps1` - 5 core tool tests (5/5 PASSED)
- `test-new-features-v2.ps1` - New feature tests (3/4 PASSED)
- Gebruik altijd ASCII characters, geen emoji's!

### Test Patronen
```powershell
Write-Host "[INFO] Starting test..." -ForegroundColor Cyan
Write-Host "[OK] Test passed!" -ForegroundColor Green
Write-Host "[FAIL] Test failed!" -ForegroundColor Red
Write-Host "[WARN] Warning!" -ForegroundColor Yellow
```

## Common Issues

### Introspection 500 Errors
- Sitecore instance ondersteunt GEEN `__schema` of `__type` queries
- Gebruik reguliere queries in plaats van introspection
- Documenteer schema handmatig via trial-and-error

### PowerShell Emoji Problemen
- Emoji's renderen als `âœ…`, `âŒ`, etc.
- Gebruik ASCII: `[OK]`, `[FAIL]`, `[PASS]`, `[WARN]`, `[INFO]`
- Gebruik kleuren voor visuele feedback

### Layout/Site Tools
- Schema parameters zijn onbekend
- Gebruik GraphQL UI om te verifiëren: [your-sitecore-instance]/sitecore/api/graph/items/master/ui
- Test queries eerst in UI, dan implementeren

## Documentation Files

Alle documentatie staat in markdown bestanden:
- **FINAL-STATUS-v1.1.md** - Complete status rapport
- **BACKLOG.md** - Product backlog
- **INSTALLATIE.md** - Multi-IDE setup
- **SCHEMA-INTROSPECTION-LIMITATIONS.md** - Introspection probleem
- **NIEUWE-FEATURES.md** - Schema scanner & natural language docs
- **QUICK-REFERENCE.md** - Command reference
- Plus 9 andere...

## Links

### Gary Wenneker
- Blog: https://www.gary.wenneker.org
- LinkedIn: https://www.linkedin.com/in/garywenneker/
- GitHub: https://github.com/GaryWenneker

### Repository
- GitHub: https://github.com/GaryWenneker/sitecore-mcp-server
- Issues: https://github.com/GaryWenneker/sitecore-mcp-server/issues

## Version

**Current Version**: 1.6.0
- 11 MCP tools (all working with production-ready best practices)
- ✅ **NEW:** Comprehensive item discovery tool (sitecore_discover_item_dependencies)
- ✅ **FIXED:** GUID format conversion (critical bug fix)
- Smart language defaults (templates always 'en')
- Helix architecture awareness
- Version management with counts
- Template-based field discovery
- Schema-validated GraphQL queries
- GUID format helper (formatGuid method)
- Comprehensive test suite (test-complete-workflow.ps1 - ALL PASSED)
- Multi-IDE support
- VSIX packaging ready

## Progress Reporting (v1.6.0+)

All MCP tools now emit concise progress updates to stderr so users see live feedback in their AI clients during longer operations. These messages are informational (no behavioral changes) and follow the rules below.

Rules:
- Always include language in messages (critical for Sitecore correctness).
- Keep messages short and action-focused: Starting → Completed.
- Use consistent prefixes: `[tool_name] message`.
- For the comprehensive discovery tool, preserve step numbers: `[Discovery X/7] message`.

Examples:
```
[sitecore_get_item] Starting (path=/sitecore/content/Home, language=nl-NL)
[sitecore_get_item] Completed: Home (template=Page, version=1)
[sitecore_search] Starting (text=Home, root=/sitecore/content, lang=nl-NL)
[sitecore_search] Completed: 34 item(s)
[sitecore_search_paginated] Completed: 50 item(s), hasNextPage=true
[Discovery 1/7] Content item retrieved: Home
```

Defaults and performance:
- Discovery tool defaults: `includeRenderings=false`, `includeResolvers=false` (opt-in, they can be slow).
- Search paginated logs report item count and `hasNextPage` to guide paging.

## Remember

1. ❌ **NOOIT emoji's in PowerShell!** Gebruik ASCII + kleuren
2. ✅ Update BACKLOG.md bij elke taak wijziging
3. ✅ Publisher is Gary Wenneker (GaryWenneker)
4. ✅ Introspection werkt NIET op deze Sitecore instance
5. ✅ Test altijd eerst in GraphQL UI voordat je implementeert
6. ✅ **ALTIJD GUID format converteren** met formatGuid() voor queries
