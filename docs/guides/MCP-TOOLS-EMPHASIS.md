# MCP Tools Emphasis Update - v1.5.0

**Date**: October 17, 2025  
**Version**: 1.5.0  
**Update**: Critical instructions update - ALWAYS use MCP tools

## 🎯 Primary Change

**Added prominent section at top of copilot-instructions.md:**

### "⚠️ CRITICAL: ALWAYS USE MCP TOOLS"

This new section **explicitly mandates** MCP tool usage and **prohibits** raw GraphQL except for testing.

## 📋 What Changed

### 1. New Top-Level Section (Added at Line 7)

**Position**: Immediately after "Project Context", before all other requirements

**Key Messages:**
- 🎯 **PRIMARY RULE: ALTIJD MCP TOOLS GEBRUIKEN!**
- ✅ MCP tools hebben fallback logic voor GraphQL limitaties
- ✅ MCP tools zijn getest en production-ready
- ❌ Raw GraphQL queries falen vaak
- ❌ PowerShell scripts zijn alleen voor testing/debugging

### 2. Clear Usage Guidelines

**WANNEER MCP TOOLS GEBRUIKEN:**
- ✅ **ALTIJD** voor content item discovery
- ✅ **ALTIJD** voor field data ophalen
- ✅ **ALTIJD** voor item references volgen
- ✅ **ALTIJD** voor search operations
- ✅ **ALTIJD** voor template/rendering/resolver info

**WANNEER RAW GRAPHQL TOEGESTAAN:**
- ⚠️ **ALLEEN** in PowerShell test scripts
- ⚠️ **ALLEEN** voor debugging/analysis
- ⚠️ **NOOIT** in MCP server code
- ⚠️ **NOOIT** in production workflows

### 3. Complete MCP Tools Reference

**All 10 tools listed with signatures:**
```javascript
sitecore_get_item({ path, language })
sitecore_get_item_fields({ path, language })
sitecore_get_children({ path, language })
sitecore_get_template({ path, language })
sitecore_get_templates({ path, language })
sitecore_search({ keyword, rootItem, language, first, after })
sitecore_get_layout({ path, language })
sitecore_get_site({ name })
sitecore_query({ query })        // Last resort
sitecore_command({ command })    // Natural language
```

### 4. Critical Workflows with Examples

**Three complete code examples added:**

**A. Content Item Discovery:**
```javascript
// ✅ CORRECT
const item = await sitecore_get_item({ path, language });
const fields = await sitecore_get_item_fields({ path, language });

// ❌ WRONG
const query = `{ item(path: "...") { fields { ... } } }`;
```

**B. Field Reference Following:**
```javascript
// ✅ CORRECT
const refs = parseFieldReferences(fields);
for (const ref of refs.PathReferences) {
  const refItem = await sitecore_get_item({
    path: ref.Path,
    language: 'en'
  });
}
```

**C. Template-Based Discovery:**
```javascript
// ✅ CORRECT
const results = await sitecore_search({
  keyword: '',
  rootItem: '/sitecore/content',
  language: 'nl-NL'
});
const items = results.filter(r => r.templateName === 'TestFeature');
```

## 🔄 Rewritten Sections

### Rule 2: "GraphQL Limitations - Use MCP Tools Instead"

**Before:** "Use Nested Children Navigation for Template Folders"

**After:** 
- ⚠️ CRITICAL GRAPHQL LIMITATIONS section
- Path Query Issues documented
- ✅ SOLUTION: Always Use MCP Tools
- Examples for templates/renderings/content
- Raw GraphQL only for test scripts

### Rule 3: "Use MCP Search for Multiple Relationships"

**Before:** "Use Search for Multiple Relationships"

**After:**
- ✅ ALWAYS Use MCP sitecore_search
- Complete code example
- ❌ NEVER Use sitecore_get_children for deep discovery
- Comparison: get_children vs search
- Helix Search Paths via MCP tools

### Section 4: "Field Discovery via MCP Tools"

**Before:** "Field Discovery via Template"

**After:**
- ⚠️ ALWAYS Use sitecore_get_item_fields
- ✅ CORRECT code example
- ❌ NEVER Use Raw GraphQL Field Queries
- Features list (5 benefits)

## 📊 Structure Changes

**Before (v1.4.1):**
```
1. Smart Language Defaults
2. Helix Architecture
3. Bidirectional Template Discovery
4. Nested Children Navigation
5. Search for relationships
6. Field Discovery
7. Schema Awareness
```

**After (v1.5.0):**
```
1. ⚠️ CRITICAL: ALWAYS USE MCP TOOLS ← NEW #1 PRIORITY
2. Smart Language Defaults
3. Helix Architecture
4. Bidirectional Template Discovery
5. GraphQL Limitations → MCP Solutions ← REWRITTEN
6. MCP Search Usage ← REWRITTEN
7. Field Discovery via MCP Tools ← ENHANCED
8. Schema Awareness
```

## ✅ Validation Checklist

- [x] Top-level MCP tools section added
- [x] Clear DO/DON'T examples provided
- [x] All 10 MCP tools listed
- [x] Critical workflows documented
- [x] Rule 2 rewritten with MCP focus
- [x] Rule 3 rewritten with MCP focus
- [x] Section 4 enhanced with MCP emphasis
- [x] Raw GraphQL marked as test-only
- [x] Links to CONTENT-DISCOVERY-STRATEGY.md
- [x] Code examples use MCP tools exclusively

## 🎯 Expected Impact

### Before
- Developers might use raw GraphQL
- Unclear when to use MCP vs GraphQL
- Mixed approach in codebase

### After
- Clear mandate: ALWAYS MCP tools
- Raw GraphQL = test scripts only
- Consistent tool usage
- Zero ambiguity

## 📁 Modified Files

**1. .github/copilot-instructions.md**
- Added: ~110 lines (new top section)
- Modified: Rule 2 (~50 lines)
- Modified: Rule 3 (~30 lines)
- Modified: Section 4 (~30 lines)
- **Total**: ~220 lines added/modified

## 📚 Supporting Documentation

**Links added to:**
- CONTENT-DISCOVERY-STRATEGY.md (complete MCP workflow)
- PATH-QUERY-LIMITATION.md (GraphQL issues)
- HELIX-RELATIONSHIP-DISCOVERY.md (template patterns)

## 📝 One-Line Summary

Added **"ALWAYS USE MCP TOOLS"** as #1 priority in instructions with complete tool reference, critical workflows, and explicit prohibition of raw GraphQL in production.

---

**Result:** Developers have **ZERO AMBIGUITY** about MCP tool usage! 🎉
