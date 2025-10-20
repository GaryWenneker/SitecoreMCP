# TestFeatures Discovery via MCP Tools

## 🎯 Complete Workflow voor Feature Discovery

Dit document toont hoe je **alle** TestFeatures gerelateerde items kunt vinden via de Sitecore MCP tools in Claude Desktop of VS Code Copilot.

## 📋 Workflow: Helix Feature Discovery

### Step 1: Template Discovery

**Command:**
```
Use sitecore_search to find all templates in /sitecore/templates/Feature/TestFeatures
```

**Expected MCP Call:**
```json
{
  "name": "sitecore_search",
  "arguments": {
    "rootPath": "/sitecore/templates/Feature/TestFeatures",
    "language": "en",
    "maxItems": 100
  }
}
```

**What You'll See:**
- All template definitions
- Template folders
- Data templates
- Field definitions

---

### Step 2: Get Template Folder Details

**Command:**
```
Get item details for /sitecore/templates/Feature/TestFeatures including all children
```

**Expected MCP Calls:**
```json
// First: Get folder
{
  "name": "sitecore_get_item",
  "arguments": {
    "path": "/sitecore/templates/Feature/TestFeatures",
    "language": "en"
  }
}

// Then: Get children
{
  "name": "sitecore_get_children",
  "arguments": {
    "path": "/sitecore/templates/Feature/TestFeatures",
    "language": "en",
    "maxItems": 100
  }
}
```

---

### Step 3: Rendering Discovery

**Command:**
```
Search for all renderings in /sitecore/layout/Renderings/Feature/TestFeatures
```

**Expected MCP Call:**
```json
{
  "name": "sitecore_search",
  "arguments": {
    "rootPath": "/sitecore/layout/Renderings/Feature/TestFeatures",
    "language": "en",
    "maxItems": 50
  }
}
```

**What You'll See:**
- Rendering definitions
- View renderings
- Controller renderings
- JSON renderings (for JSS/Headless)

---

### Step 4: Content Resolver Discovery

**Command:**
```
Find all content resolvers in /sitecore/system/Modules/Layout Service/Rendering Contents Resolvers/Feature/TestFeatures
```

**Expected MCP Call:**
```json
{
  "name": "sitecore_search",
  "arguments": {
    "rootPath": "/sitecore/system/Modules/Layout Service/Rendering Contents Resolvers/Feature/TestFeatures",
    "language": "en",
    "maxItems": 50
  }
}
```

---

### Step 5: Content Item Discovery

**Command:**
```
Find all content items in /sitecore/content that use TestFeatures templates
```

**Approach A: Search by keyword**
```json
{
  "name": "sitecore_search",
  "arguments": {
    "searchText": "TestFeatures",
    "rootPath": "/sitecore/content",
    "language": "en",
    "maxItems": 100
  }
}
```

**Approach B: Search by template name (if you know it)**
```json
{
  "name": "sitecore_search",
  "arguments": {
    "templateName": "TestFeature Item",
    "rootPath": "/sitecore/content",
    "language": "en",
    "maxItems": 100
  }
}
```

---

### Step 6: Global Search

**Command:**
```
Search the entire Sitecore database for anything related to TestFeatures
```

**Expected MCP Call:**
```json
{
  "name": "sitecore_search",
  "arguments": {
    "searchText": "TestFeatures",
    "language": "en",
    "maxItems": 200
  }
}
```

**What You'll See:**
- All items with "TestFeatures" in name or path
- Templates, renderings, resolvers, content items
- System items
- Configuration items

---

## 🚀 Complete Example Conversation

### In Claude Desktop

**You:**
```
I need to discover all items related to the TestFeatures module in Sitecore. 
Can you use the MCP tools to find:
1. All templates in the Feature layer
2. All renderings
3. All content resolvers
4. All content items using these templates

Show me a complete inventory with the Helix relationship map.
```

**Claude will:**
1. Call `sitecore_search` for templates path
2. Call `sitecore_get_children` for template details
3. Call `sitecore_search` for renderings path
4. Call `sitecore_search` for resolvers path
5. Call `sitecore_search` for content items
6. Compile a complete inventory
7. Show Helix relationship map

**Expected Output:**
```
🎯 TestFeatures Module Inventory

📁 Templates (5 items found)
  Location: /sitecore/templates/Feature/TestFeatures
  - TestFeature Item
  - TestFeature Settings
  - TestFeature Data
  - _TestFeature Base
  - Data Templates/

📊 Renderings (3 items found)
  Location: /sitecore/layout/Renderings/Feature/TestFeatures
  - TestFeature List
  - TestFeature Detail
  - TestFeature Navigation

🔧 Content Resolvers (2 items found)
  Location: /sitecore/system/.../Feature/TestFeatures
  - TestFeature List Resolver
  - TestFeature Detail Resolver

📄 Content Items (12 items found)
  Using TestFeature templates:
  - /sitecore/content/MySite/Home/TestItem1
  - /sitecore/content/MySite/Home/TestItem2
  - ... (10 more)

🔗 Helix Relationship Map
  Feature Module: TestFeatures
  ├── Templates (Foundation layer)
  ├── Renderings (Presentation layer)
  ├── Resolvers (API layer)
  └── Content Items (Content layer)
```

---

### In VS Code Copilot

**You:**
```
@workspace Use Sitecore MCP to find all TestFeatures items:
- Templates in /sitecore/templates/Feature/TestFeatures
- Renderings in /sitecore/layout/Renderings/Feature/TestFeatures
- Content items using TestFeatures templates

Create a markdown summary with item counts and paths.
```

**Copilot will:**
1. Use MCP tools to gather data
2. Create markdown file with results
3. Show Helix structure
4. List all items with details

---

## 🔍 Advanced Queries

### Find Items by Template ID

If you discovered a template and want all content using it:

**Command:**
```
Find all content items using template ID {ABC-123-DEF-456}
```

**Expected MCP Call:**
```json
{
  "name": "sitecore_search",
  "arguments": {
    "rootPath": "/sitecore/content",
    "filters": {
      "templateIn": ["{ABC-123-DEF-456}"]
    },
    "language": "en",
    "maxItems": 100
  }
}
```

---

### Get Template Details

**Command:**
```
Show me the complete template definition for /sitecore/templates/Feature/TestFeatures/TestFeature Item
```

**Expected MCP Call:**
```json
{
  "name": "sitecore_get_template",
  "arguments": {
    "templatePath": "/sitecore/templates/Feature/TestFeatures/TestFeature Item",
    "language": "en"
  }
}
```

**What You'll See:**
- Template ID
- All fields (including inherited)
- Field types
- Base templates
- Standard values

---

### Get All Fields from Content Item

**Command:**
```
Get all field values from /sitecore/content/MySite/Home/TestItem1
```

**Expected MCP Calls:**
```json
// First: Get item to find template
{
  "name": "sitecore_get_item",
  "arguments": {
    "path": "/sitecore/content/MySite/Home/TestItem1",
    "language": "en"
  }
}

// Then: Get all fields
{
  "name": "sitecore_get_item_fields",
  "arguments": {
    "path": "/sitecore/content/MySite/Home/TestItem1",
    "language": "en"
  }
}
```

---

## 📊 Filtering and Sorting

### Filter by Path Contains

**Command:**
```
Find all items with "TestFeatures" in their path
```

**Expected MCP Call:**
```json
{
  "name": "sitecore_search",
  "arguments": {
    "searchText": "TestFeatures",
    "filters": {
      "pathContains": "TestFeatures"
    },
    "language": "en",
    "maxItems": 100
  }
}
```

---

### Sort by Name

**Command:**
```
Search TestFeatures templates and sort by name
```

**Expected MCP Call:**
```json
{
  "name": "sitecore_search",
  "arguments": {
    "rootPath": "/sitecore/templates/Feature/TestFeatures",
    "orderBy": [
      { "field": "name", "direction": "ASC" }
    ],
    "language": "en",
    "maxItems": 100
  }
}
```

---

## 🎯 Use Cases

### Use Case 1: Audit Feature Module

**Goal:** Check if all Helix locations have items

**Commands:**
1. Search templates → Should have > 0 items
2. Search renderings → Should have > 0 items
3. Search resolvers → Should have > 0 items
4. Search content → Should have > 0 items

**Result:** Complete audit report

---

### Use Case 2: Find Orphaned Content

**Goal:** Find content items with no template

**Command:**
```
Find all content items in /sitecore/content where template contains "TestFeatures"
then check if those templates still exist in /sitecore/templates/Feature/TestFeatures
```

**Process:**
1. Get all content items using TestFeatures templates
2. Get all templates in TestFeatures folder
3. Compare: content.templateName IN templates.names
4. Report orphans

---

### Use Case 3: Template Usage Report

**Goal:** How many content items use each template?

**Commands:**
1. Get all templates in TestFeatures
2. For each template:
   - Search content by template name
   - Count results
3. Create usage report

---

## ⚠️ Important Notes

### Language Defaults

**System Items (Templates, Renderings, Resolvers):**
- ✅ **ALWAYS use 'en'** (Sitecore standard)
- ❌ Never use 'nl' or other languages for system items

**Content Items:**
- ✅ Can be multilingual
- ✅ Default to 'en' if not specified
- ✅ Specify language if needed: `"language": "nl"`

### Schema Differences

**Item queries** (get_item, get_children):
- ✅ Returns `displayName`, `template { id, name }`, `hasChildren`, `fields[]`

**Search queries** (sitecore_search):
- ✅ Returns `name`, `templateName`, `uri`, `language` (String)
- ❌ NO: `displayName`, `template`, `hasChildren`, `fields`

### Performance

- Use `rootPath` to narrow search scope
- Use `maxItems` to limit results (default: 50)
- Use `filters` for client-side filtering
- Use `orderBy` for sorting

---

## 📚 Related Documentation

- **HELIX-RELATIONSHIP-DISCOVERY.md** - Helix patterns
- **test-testfeatures-discovery.ps1** - Automated test script
- **TEST-TESTFEATURES-README.md** - Test script documentation
- **SCHEMA-FIX-COMPLETE.md** - GraphQL schema reference

---

## ✅ Success Checklist

After completing discovery, you should have:

- [ ] Complete list of templates
- [ ] Complete list of renderings
- [ ] Complete list of content resolvers
- [ ] Complete list of content items
- [ ] Helix relationship map
- [ ] Template usage statistics
- [ ] No GraphQL errors
- [ ] All Helix locations validated

**Status: READY FOR PRODUCTION** 🚀
