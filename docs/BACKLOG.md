# Sitecore MCP Server - Product Backlog

## 🔴 Priority 1: Critical (Must Have)

### 1.0 Security Hardening & VSIX Packaging ✅ COMPLETED
**Story:** As a developer I want a secure codebase without hardcoded credentials and working VSIX packaging.

**Tasks:**
- [x] Replace all emojis in PowerShell scripts with ASCII + colors
- [x] Test scripts with ASCII output (test-new-features.ps1, test-new-features-v2.ps1)
- [x] Add publisher info to package.json (Gary Wenneker / GaryWenneker)
- [x] Add repository links (GitHub)
- [x] Add blog link (https://www.gary.wenneker.org)
- [x] Add LinkedIn link to docs
- [x] Create copilot-instructions.md with all critical info
- [x] Remove all hardcoded credentials (78 instances)
- [x] Implement .env file support
- [x] Create Load-DotEnv.ps1 helper script
- [x] Update all test scripts with .env loader
- [x] Create .vscodeignore file
- [x] Create LICENSE file (MIT)
- [x] Fix package.json for VSIX (vscode engine, activationEvents)
- [x] Create build-vsix.ps1 script
- [x] Test VSIX packaging (14.43 KB, 11 files)
- [x] Document security approach (SECURITY.md)
- [x] Improve sitecore_command description
- [x] Make GraphQL endpoint configurable (SITECORE_ENDPOINT)
- [x] Support for /sitecore/api/graph/edge (default)
- [x] Support for /sitecore/api/graph/items/master (alternative)
- [x] Document endpoint options (CONFIGURABLE-ENDPOINT.md)

**Acceptance Criteria:**
- ✅ PowerShell scripts show no strange characters
- ✅ ASCII characters with colors work correctly
- ✅ No hardcoded credentials in codebase
- ✅ .env file required and documented
- ✅ VSIX package build successful
- ✅ Package.json complete with publisher info
- ✅ sitecore_command has clear description

**Note:** Security is now priority #1. All credentials via environment variables.

**Estimate:** 30 minutes → 2 hours (actual)
**Dependencies:** None
**Status:** ✅ COMPLETED (16-10-2025)

---

### 1.1 Layout & Site Tools - ✅ COMPLETED
**Story:** As a developer I want to retrieve layout/presentation and site configuration.

**Status:** ✅ COMPLETED
- Schema downloaded and analyzed (65 MB, 1,594 types)
- Parameters fixed to schema specification
- .env updated to `/edge` endpoint
- Tools updated in MCP

**Tasks:**
- [x] Download GraphQL schema (download-schema.ps1)
- [x] Analyze schema queries and parameters
- [x] Fix `sitecore_get_layout` parameters (site, routePath, language)
- [x] Fix `sitecore_get_site` parameters (no parameters)
- [x] Update tool definitions in index.ts
- [x] Update handlers in index.ts
- [x] Update .env to edge endpoint
- [x] Rebuild TypeScript
- [x] Document findings (SCHEMA-ANALYSIS-FULL.md)

**Acceptance Criteria:**
- ✅ Layout query uses correct parameters (site, routePath)
- ✅ Site query retrieves all sites (no parameters)
- ✅ Schema fully analyzed
- ✅ Tools available in MCP
- ✅ .env uses working endpoint

**Estimate:** 20 minutes → 45 minutes (actual)
**Dependencies:** ✅ Schema download complete

**Findings:**
- `/items/master` endpoint: 403 Forbidden
- `/edge` endpoint: Works perfectly
- Layout expects: site + routePath (not path/id)
- Site expects: no parameters (return all sites)
- 1,594 types available in schema

---

### 1.2 Git Repository Setup & NPM Publication
**Story:** As a developer I want to publish the code on GitHub and NPM so others can use it.

**Tasks:**
- [ ] Create GitHub repository: GaryWenneker/sitecore-mcp-server
- [ ] Push code to GitHub
- [ ] Create v1.1.0 tag
- [ ] Write CHANGELOG.md
- [ ] Test npm pack locally
- [ ] Publish to NPM registry
- [ ] Update README with npm install instructions
- [ ] Add badges (npm version, downloads, license)
- [ ] Create GitHub releases notes

**Acceptance Criteria:**
- Code visible on GitHub
- NPM package published
- `npm install sitecore-mcp-server` works
- README up-to-date with installation instructions
- CHANGELOG describes v1.1.0 features

**Estimate:** 30 minutes
**Dependencies:** Clean codebase (✅ done)
**Status:** 🔜 NEXT

---

### 1.3 Generieke Schema Scanner - ✅ COMPLETED
**Story:** Als developer wil ik automatisch GraphQL schemas kunnen scannen zodat ik snel nieuwe endpoints kan integreren.

**Status:** ✅ COMPLETED
- Schema scanner tool geïmplementeerd
- Download-schema.ps1 script werkt
- Analyse scripts werken
- Schema opgeslagen en gedocumenteerd

**Tasks:**
- [x] Implementeer download-schema.ps1
- [x] Download schema via introspection query
- [x] Parse schema en extract Query type fields
- [x] Analyseer argumenten en return types
- [x] Genereer rapport met beschikbare operaties
- [x] Sla schema analyse op in JSON bestand
- [x] Auto-detect welke operations beschikbaar zijn
- [x] Maak SCHEMA-ANALYSIS-FULL.md documentatie

**Acceptatie Criteria:**
- ✅ Schema scan werkt voor GraphQL endpoint
- ✅ Genereert leesbaar analyse rapport
- ✅ Detecteert Query type (1,594 types)
- ✅ Lijst alle fields met argumenten en return types
- ✅ JSON output (graphql-schema-full.json, 65 MB)
- ✅ Summary (graphql-schema-summary.json)

**Deliverables:**
- download-schema.ps1
- analyze-schema.ps1
- graphql-schema-full.json (65.65 MB)
- graphql-schema-summary.json
- SCHEMA-ANALYSIS-FULL.md

**Estimate:** 2 uur → 1 uur (actual)
**Dependencies:** ✅ Geen

**Note:** `sitecore_scan_schema` tool bestaat maar werkt niet vanwege schema complexity. Gebruik download-schema.ps1 script in plaats daarvan.

---

### 1.4 Schema-Based Tool Generator
**Story:** Als developer wil ik automatisch MCP tools genereren uit schema analyse zodat ik snel alle operaties kan gebruiken.

**Tasks:**
- [ ] Lees schema analyse JSON
- [ ] Genereer TypeScript method voor elke Query field
- [ ] Genereer MCP tool definition voor elke operation
- [ ] Auto-detect required vs optional parameters
- [ ] Genereer type-safe parameter handling
- [ ] Genereer test cases per tool
- [ ] Update index.ts met nieuwe tools

**Acceptatie Criteria:**
- Genereert werkende TypeScript methods
- Genereert correcte MCP tool definitions
- Type safety voor alle parameters
- Automatische documentatie generatie
- Hot-reload support (optioneel)

**Estimate:** 4 uur
**Dependencies:** Schema Scanner (1.3)

---

## 🟠 Prioriteit 2: High (Should Have)

### 2.1 Enhanced Search Filters
**Story:** Als developer wil ik geavanceerde zoek filters gebruiken zodat ik preciezere queries kan uitvoeren.

**Tasks:**
- [ ] Implementeer `path_contains` filter
- [ ] Implementeer `path_starts_with` filter
- [ ] Implementeer `name_contains` filter
- [ ] Implementeer `template_in` array filter
- [ ] Implementeer `hasChildren` boolean filter
- [ ] Implementeer `hasLayout` boolean filter
- [ ] Implementeer `AND` combinatie filter
- [ ] Implementeer `OR` combinatie filter
- [ ] Update `searchItems()` method
- [ ] Update tool schema met nieuwe filters
- [ ] Voeg test cases toe

**Acceptatie Criteria:**
- Alle filter operatoren werken correct
- Combinatie filters (AND/OR) werken
- Backwards compatible met bestaande searches
- Tests passing

**Estimate:** 1 uur
**Dependencies:** Geen

---

### 2.2 Pagination Support
**Story:** Als developer wil ik door grote resultaat sets kunnen navigeren zodat ik niet alle data in één keer hoef te laden.

**Tasks:**
- [ ] Implementeer cursor-based pagination
- [ ] Support `first` parameter (aantal items)
- [ ] Support `after` cursor (volgende pagina)
- [ ] Support `before` cursor (vorige pagina)
- [ ] Support `last` parameter (laatste items)
- [ ] Return `pageInfo` met hasNextPage/hasPreviousPage
- [ ] Return cursors in resultaten
- [ ] Update alle relevante tools (search, children, etc.)
- [ ] Voeg pagination test cases toe

**Acceptatie Criteria:**
- Forward pagination werkt (first/after)
- Backward pagination werkt (last/before)
- PageInfo correct gereturned
- Cursors kunnen hergebruikt worden
- Tests passing

**Estimate:** 1.5 uur
**Dependencies:** Geen

---

### 2.3 Search Ordering
**Story:** Als developer wil ik zoekresultaten kunnen sorteren zodat ik data in gewenste volgorde krijg.

**Tasks:**
- [ ] Implementeer `orderBy` parameter
- [ ] Support sortering op `name` (ASC/DESC)
- [ ] Support sortering op `displayName`
- [ ] Support sortering op `path`
- [ ] Support sortering op `created` datum
- [ ] Support sortering op `updated` datum
- [ ] Support multiple sort fields
- [ ] Update search tool met orderBy
- [ ] Voeg sorting test cases toe

**Acceptatie Criteria:**
- Alle sort fields werken
- ASC en DESC ordering correct
- Multiple sort fields mogelijk
- Tests passing

**Estimate:** 45 minuten
**Dependencies:** Geen

---

### 2.4 `/sitecore` Chat Commando ✅ COMPLETED
**Story:** Als gebruiker wil ik `/sitecore` kunnen typen in chat zodat ik snel toegang heb tot Sitecore MCP functionaliteit.

**Status:** ✅ COMPLETED (16-10-2025)

**Tasks:**
- [x] Implementeer custom prompt handler voor `/sitecore`
- [x] Parse natuurlijke taal commands (15+ patterns)
- [x] Map naar juiste MCP tools
- [x] Intelligente parameter extractie
- [x] Context-aware suggesties
- [x] Error handling met nuttige feedback
- [x] Help commando `/sitecore help`
- [x] Voorbeelden `/sitecore examples`
- [x] Version support (`/sitecore get PATH version N`)
- [x] Template search (`/sitecore find items with template X`)
- [x] Path-specific search (`/sitecore search X in PATH`)
- [x] Beautiful markdown formatting
- [x] Emoji icons per command type
- [x] Smart error messages with suggestions

**Acceptatie Criteria:**
- ✅ `/sitecore get item /sitecore/content/Home` werkt
- ✅ `/sitecore /sitecore/content/Home` werkt (short syntax)
- ✅ `/sitecore search articles` werkt
- ✅ `/sitecore search for "home" in /sitecore/content` werkt
- ✅ `/sitecore find items with template Article` werkt
- ✅ `/sitecore children of /sitecore/content` werkt
- ✅ `/sitecore field Title from /sitecore/content/Home` werkt
- ✅ `/sitecore templates` werkt (lists templates)
- ✅ `/sitecore sites` werkt (lists sites)
- ✅ `/sitecore create/update/delete` werkt (with error handling)
- ✅ `/sitecore help` toont alle commando's
- ✅ `/sitecore examples` toont categorized examples
- ✅ Natuurlijke taal parsing werkt (15+ patterns)
- ✅ Slimme foutmeldingen met suggesties
- ✅ Beautiful formatted output met markdown

**Features Implemented:**
1. **15+ Command Patterns:**
   - `get item PATH` / `get PATH` / just `PATH`
   - `get PATH version N`
   - `search KEYWORD` / `search for "KEYWORD"`
   - `search KEYWORD in PATH`
   - `find items with template TEMPLATE`
   - `children of PATH`
   - `field FIELD from PATH`
   - `templates` / `sites`
   - `create item NAME with template X under PATH`
   - `update item PATH name NAME`
   - `delete item PATH`
   - `help` / `examples` / `scan schema`

2. **Smart Features:**
   - Auto-remove `/sitecore` prefix
   - Pattern matching with regex
   - Parameter extraction from natural language
   - Error handling with permission checks
   - Contextual suggestions on unknown commands

3. **Beautiful Output:**
   - Markdown headers with emoji icons
   - Formatted item details
   - Categorized examples
   - Code blocks for paths/IDs
   - Color-coded sections

**Estimate:** 3 uur → 2.5 uur (actual)
**Dependencies:** Geen

---

## 🟡 Prioriteit 3: Medium (Could Have)

### 3.1 Multi-Language Support ✅ COMPLETED
**Story:** Als developer wil ik items in verschillende talen kunnen ophalen zodat ik meertalige sites kan ondersteunen.

**Status:** ✅ COMPLETED (v1.3.0)

**Tasks:**
- [x] Add `language` parameter aan alle tools waar relevant
- [x] Default naar "en" maar support alle Sitecore talen
- [x] Validate language codes
- [x] Update alle queries met language support
- [x] Voeg language tests toe

**Acceptatie Criteria:**
- ✅ Alle tools accepteren language parameter
- ✅ Correcte taal versie gereturned
- ✅ Tests voor NL, EN, nl-NL

**Note:** Already implemented in v1.0, enhanced error messages in v1.2.1

**Estimate:** 1 uur → Completed
**Dependencies:** Geen

---

### 3.2 Version Support ✅ COMPLETED
**Story:** Als developer wil ik specifieke versies van items kunnen ophalen zodat ik versie geschiedenis kan inspecteren.

**Status:** ✅ COMPLETED (v1.3.0 - 16-10-2025)

**Tasks:**
- [x] Add `version` parameter aan item queries
- [x] Support version number (1, 2, 3, etc.)
- [x] Update getItem with version support
- [x] Update getChildren with version support
- [x] Update getFieldValue with version support
- [x] Implement getItemVersions() method
- [x] Voeg version tests toe

**Acceptatie Criteria:**
- ✅ Specifieke versies ophaalbaar
- ✅ Version parameter works on getItem, getChildren, getFieldValue
- ✅ New tool: sitecore_get_item_versions
- ✅ Tests passing (5/5 in test-new-features-v1.3.ps1)

**Deliverables:**
- Updated sitecore_get_item with version param
- Updated sitecore_get_children with version param
- Updated sitecore_get_field_value with version param
- New tool: sitecore_get_item_versions
- Test script: test-new-features-v1.3.ps1

**Estimate:** 1 uur → 45 minuten (actual)
**Dependencies:** Geen

---

### 3.3 Parent Navigation ✅ COMPLETED
**Story:** Als developer wil ik naar parent items kunnen navigeren zodat ik de item hiërarchie kan verkennen.

**Status:** ✅ COMPLETED (v1.3.0 - 16-10-2025)

**Tasks:**
- [x] Implementeer `getParent()` method
- [x] Support recursive parent traversal
- [x] Get all ancestors tot root
- [x] Safety check voor infinite loops (max 50)
- [x] Nieuwe tool `sitecore_get_parent`
- [x] Nieuwe tool `sitecore_get_ancestors`
- [x] Voeg navigation tests toe

**Acceptatie Criteria:**
- ✅ Parent items ophaalbaar
- ✅ Ancestors lijst compleet met breadcrumb
- ✅ Path traversal werkt
- ✅ Tests passing

**Deliverables:**
- New method: getParent()
- New method: getAncestors()
- New tool: sitecore_get_parent
- New tool: sitecore_get_ancestors
- Breadcrumb formatting in response

**Estimate:** 45 minuten → 30 minuten (actual)
**Dependencies:** Geen

---

### 3.4 Item Statistics ✅ COMPLETED
**Story:** Als developer wil ik created/updated dates en users kunnen ophalen voor audit trail.

**Status:** ✅ COMPLETED (v1.3.0 - 16-10-2025)

**Tasks:**
- [x] Implement Statistics inline fragment
- [x] Handle DateField type (requires { value })
- [x] Handle TextField type (requires { value })
- [x] created.value, updated.value
- [x] createdBy.value, updatedBy.value
- [x] New tool sitecore_get_item_with_statistics
- [x] Test Statistics query

**Acceptatie Criteria:**
- ✅ Statistics data retrieved correctly
- ✅ DateField and TextField subselections work
- ✅ All 4 fields return proper values
- ✅ Tests passing

**Deliverables:**
- New method: getItemWithStatistics()
- New tool: sitecore_get_item_with_statistics
- Proper inline fragment implementation

**Estimate:** 1 uur → 1 uur (actual, including schema discovery)
**Dependencies:** Geen

---

### 3.5 URL-Based Queries
**Story:** Als developer wil ik items in verschillende talen kunnen ophalen zodat ik meertalige sites kan ondersteunen.

**Tasks:**
- [ ] Add `language` parameter aan alle tools waar relevant
- [ ] Default naar "en" maar support alle Sitecore talen
- [ ] Language fallback logica
- [ ] List available languages per item
- [ ] Validate language codes
- [ ] Update alle queries met language support
- [ ] Voeg language tests toe

**Acceptatie Criteria:**
- Alle tools accepteren language parameter
- Correcte taal versie gereturned
- Fallback naar default language werkt
- Tests voor NL, EN, DE, FR

**Estimate:** 1 uur
**Dependencies:** Geen

---

### 3.2 Version Support
**Story:** Als developer wil ik specifieke versies van items kunnen ophalen zodat ik versie geschiedenis kan inspecteren.

**Tasks:**
- [ ] Add `version` parameter aan item queries
- [ ] Support version number (1, 2, 3, etc.)
- [ ] Support "latest" alias
- [ ] List all versions van een item
- [ ] Version compare functionaliteit
- [ ] Update queries met version support
- [ ] Voeg version tests toe

**Acceptatie Criteria:**
- Specifieke versies ophaalbaar
- Latest version alias werkt
- Version listing werkt
- Tests passing

**Estimate:** 1 uur
**Dependencies:** Geen

---

### 3.3 Parent Navigation
**Story:** Als developer wil ik naar parent items kunnen navigeren zodat ik de item hiërarchie kan verkennen.

**Tasks:**
- [ ] Implementeer `getParent()` method
- [ ] Support recursive parent traversal
- [ ] Get all ancestors tot root
- [ ] Get path als array van items
- [ ] Nieuwe tool `sitecore_get_parent`
- [ ] Nieuwe tool `sitecore_get_ancestors`
- [ ] Voeg navigation tests toe

**Acceptatie Criteria:**
- Parent items ophaalbaar
- Ancestors lijst compleet
- Path traversal werkt
- Tests passing

**Estimate:** 45 minuten
**Dependencies:** Geen

---

### 3.4 URL-Based Queries
**Story:** Als developer wil ik items kunnen ophalen via URL zodat ik frontend routes kan resolven.

**Tasks:**
- [ ] Implementeer `getItemByUrl()` method
- [ ] URL parsing en normalisatie
- [ ] Site context resolution
- [ ] Support voor friendly URLs
- [ ] Support voor canonical URLs
- [ ] Nieuwe tool `sitecore_get_item_by_url`
- [ ] Voeg URL tests toe

**Acceptatie Criteria:**
- URL resolves naar correct item
- Verschillende URL formaten supported
- Site context correct
- Tests passing

**Estimate:** 1 uur
**Dependencies:** Site tool (1.2)

---

### 3.5 Bulk Operations
**Story:** Als developer wil ik meerdere items tegelijk kunnen ophalen zodat ik efficiënt kan werken met grote datasets.

**Tasks:**
- [ ] Implementeer `getItemsBatch()` method
- [ ] Accept array van paths of IDs
- [ ] Parallel execution
- [ ] Error handling per item
- [ ] Nieuwe tool `sitecore_get_items_batch`
- [ ] Optimalisatie voor GraphQL batching
- [ ] Voeg batch tests toe

**Acceptatie Criteria:**
- Multiple items in één call
- Performance beter dan sequential
- Partial failures handled
- Tests passing

**Estimate:** 1.5 uur
**Dependencies:** Geen

---

## 🟢 Prioriteit 4: Low (Nice to Have)

### 4.1 Field Type Support
**Story:** Als developer wil ik field types kunnen detecteren zodat ik data correct kan parsen.

**Tasks:**
- [ ] Detect field types (text, rich text, image, etc.)
- [ ] Type-specific parsing
- [ ] Structured field data (Image: src, alt, etc.)
- [ ] Link field parsing
- [ ] Rich text field parsing
- [ ] Update `getFieldValue()` met type info
- [ ] Voeg type tests toe

**Acceptatie Criteria:**
- Alle standaard field types detected
- Type-specific data structure
- Backwards compatible
- Tests passing

**Estimate:** 2 uur
**Dependencies:** Geen

---

### 4.2 Template Inheritance
**Story:** Als developer wil ik template inheritance kunnen zien zodat ik alle beschikbare fields kan ontdekken.

**Tasks:**
- [ ] Query base templates
- [ ] Recursive template traversal
- [ ] Flatten inherited fields
- [ ] Field overrides detecteren
- [ ] Update `getTemplate()` met inheritance
- [ ] Voeg inheritance tests toe

**Acceptatie Criteria:**
- Base templates opgehaald
- All inherited fields visible
- Override detection werkt
- Tests passing

**Estimate:** 1 uur
**Dependencies:** Geen

---

### 4.3 Rendering Parameters
**Story:** Als developer wil ik rendering parameters kunnen ophalen en wijzigen zodat ik presentation kan configureren.

**Tasks:**
- [ ] Parse rendering parameters
- [ ] Structured parameter data
- [ ] Default values ophalen
- [ ] Parameter validation
- [ ] Update layout queries
- [ ] Voeg parameter tests toe

**Acceptatie Criteria:**
- Parameters correct geparsed
- Structure data returned
- Validation werkt
- Tests passing

**Estimate:** 1.5 uur
**Dependencies:** Layout tool (1.1)

---

### 4.4 Caching Layer
**Story:** Als developer wil ik caching hebben zodat repeated queries sneller zijn.

**Tasks:**
- [ ] Implementeer in-memory cache
- [ ] TTL configuratie
- [ ] Cache invalidatie
- [ ] Cache statistics
- [ ] Configureerbare cache size
- [ ] Per-tool cache control
- [ ] Voeg cache tests toe

**Acceptatie Criteria:**
- Repeated queries cached
- TTL werkt correct
- Invalidation werkt
- Performance improvement meetbaar
- Tests passing

**Estimate:** 2 uur
**Dependencies:** Geen

---

### 4.5 GraphQL Mutations
**Story:** Als developer wil ik items kunnen aanmaken/wijzigen via MCP zodat ik Sitecore kan beheren vanuit chat.

**Tasks:**
- [ ] Detect Mutation type in schema
- [ ] Implementeer create item
- [ ] Implementeer update item
- [ ] Implementeer delete item
- [ ] Implementeer update field
- [ ] Permission handling
- [ ] Validation
- [ ] Voeg mutation tests toe

**Acceptatie Criteria:**
- Create/update/delete werkt
- Permissions gerespecteerd
- Validation werkt
- Safe defaults
- Tests passing

**Estimate:** 4 uur
**Dependencies:** Schema Scanner (1.3)

---

## 📋 Technical Debt

### TD-1: Error Handling Verbetering
- [ ] Consistent error types
- [ ] Better error messages
- [ ] Error codes
- [ ] Retry logic voor transient errors
- [ ] Circuit breaker pattern

**Estimate:** 1 uur

---

### TD-2: Logging & Monitoring
- [ ] Structured logging
- [ ] Performance metrics
- [ ] Request tracing
- [ ] Error tracking
- [ ] Usage statistics

**Estimate:** 1.5 uur

---

### TD-3: Type Safety Verbetering
- [ ] Stricter TypeScript types
- [ ] Runtime type validation
- [ ] Schema-to-TypeScript codegen
- [ ] Better null handling

**Estimate:** 2 uur

---

### TD-4: Test Coverage
- [ ] Unit tests voor alle methods
- [ ] Integration tests
- [ ] E2E tests
- [ ] Test automation
- [ ] Coverage reporting

**Estimate:** 3 uur

---

### TD-5: Documentation
- [ ] JSDoc comments overal
- [ ] API reference docs
- [ ] Usage examples
- [ ] Architecture docs
- [ ] Contributing guide

**Estimate:** 2 uur

---

## 🎯 Sprint Planning

### Sprint 1: Critical Features (Week 1)
**Goal:** Alle Priority 1 features werkend

**Stories:**
- 1.1 Fix Layout Tool (10 min)
- 1.2 Fix Site Tool (10 min)
- 1.3 Schema Scanner (2 uur)
- 1.4 Tool Generator (4 uur)

**Total:** ~6.5 uur

---

### Sprint 2: Enhanced Search (Week 2)
**Goal:** Advanced search capabilities

**Stories:**
- 2.1 Enhanced Filters (1 uur)
- 2.2 Pagination (1.5 uur)
- 2.3 Ordering (45 min)

**Total:** ~3.25 uur

---

### Sprint 3: UX Improvements (Week 3)
**Goal:** Better user experience

**Stories:**
- 2.4 `/sitecore` Commando (3 uur)
- 3.1 Multi-Language (1 uur)
- 3.2 Version Support (1 uur)

**Total:** ~5 uur

---

### Sprint 4: Advanced Features (Week 4)
**Goal:** Power user features

**Stories:**
- 3.3 Parent Navigation (45 min)
- 3.4 URL Queries (1 uur)
- 3.5 Bulk Operations (1.5 uur)

**Total:** ~3.25 uur

---

## 📊 Metrics & Success Criteria

### Performance
- [ ] Schema scan < 5 seconden
- [ ] Item query < 500ms
- [ ] Search < 1 seconde
- [ ] Bulk operations > 10 items/seconde

### Quality
- [ ] Test coverage > 80%
- [ ] Zero critical bugs
- [ ] < 5 known issues
- [ ] All tools documented

### Usage
- [ ] 8/8 tools werkend (100%)
- [ ] > 10 queries per dag
- [ ] User satisfaction > 4/5

---

## 🔄 Backlog Refinement

**Next Review:** Weekly
**Estimation Method:** T-shirt sizing (S/M/L/XL)
**Priority Method:** MoSCoW (Must/Should/Could/Won't)

**Labels:**
- `bug` - Defect die gefixt moet
- `enhancement` - Nieuwe feature
- `technical-debt` - Code quality improvement
- `documentation` - Docs improvement
- `performance` - Speed optimization
- `breaking-change` - API breaking change
