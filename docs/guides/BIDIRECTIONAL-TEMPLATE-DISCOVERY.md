# Bidirectional Template-Based Discovery

**Versie:** 1.5.0  
**Datum:** 17 oktober 2025  
**Status:** ⚠️ CRITICAL INSTRUCTION  
**Impact:** Alle relationship discovery workflows

---

## 🎯 Core Principle

**Templates zijn de brug tussen content en architectuur.**

Bij **ELKE** discovery in Sitecore MCP MOET je bidirectioneel navigeren via templates:

```
Content ←→ Template ←→ Related Content
```

**Dit is NIET optioneel. Dit is CRITICAL voor correcte Helix discovery.**

---

## ⚠️ CRITICAL RULE

### Content Item Discovery
**Wanneer je een content item vindt:**
1. ✅ **ALTIJD** de template analyseren
2. ✅ **ALTIJD** zoeken naar andere content items met dezelfde template
3. ✅ **ALTIJD** feature locaties zoeken (templates, renderings, resolvers)

### Template Discovery
**Wanneer je een template vindt:**
1. ✅ **ALTIJD** zoeken naar alle content items die deze template gebruiken
2. ✅ **ALTIJD** content distributie analyseren (sites, languages, locaties)
3. ✅ **ALTIJD** usage statistics genereren

---

## 🔄 Bidirectional Flows

### Flow A: Content → Template → Related Content (Upward)

```typescript
// STAP 1: Get content item
const item = await sitecore_get_item({
  path: '/sitecore/content/MySite/Home/Article1',
  language: 'en'
});

// STAP 2: Extract template information
const templatePath = item.template.path;  
// Result: "/sitecore/templates/Feature/Articles/Article"

const featureName = templatePath.split('/')[4];  
// Result: "Articles"

const templateName = item.template.name;  
// Result: "Article"

// STAP 3A: Search ALL content using same template (CRITICAL!)
const relatedContent = await sitecore_search({
  templateName: templateName,      // "Article"
  rootPath: '/sitecore/content',
  language: 'en',
  maxItems: 100
});
// Result: Article1, Article2, Article3, ... (12 items found)

// STAP 3B: Search feature definition locations
const templateItems = await sitecore_search({
  rootPath: `/sitecore/templates/Feature/${featureName}`,
  language: 'en'
});

const renderingItems = await sitecore_search({
  rootPath: `/sitecore/layout/Renderings/Feature/${featureName}`,
  language: 'en'
});

const resolverItems = await sitecore_search({
  rootPath: `/sitecore/system/Modules/Layout Service/Rendering Contents Resolvers/Feature/${featureName}`,
  language: 'en'
});
```

**Output:**
```
📄 Content Item: Article1
  Template: Article (Feature: Articles)
  
🔗 Related Content (same template):
  - Article1 (/sitecore/content/MySite/Home/Article1)
  - Article2 (/sitecore/content/MySite/News/Article2)
  - Article3 (/sitecore/content/MySite/Blog/Article3)
  ... (12 total)

📁 Feature Locations:
  Templates: /sitecore/templates/Feature/Articles (5 items)
  Renderings: /sitecore/layout/Renderings/Feature/Articles (3 items)
  Resolvers: /sitecore/system/.../Feature/Articles (2 items)
```

---

### Flow B: Template → Content (Downward)

```typescript
// STAP 1: Get template definition
const template = await sitecore_get_template({
  templatePath: '/sitecore/templates/Feature/Articles/Article',
  language: 'en'
});

// STAP 2: Extract template name
const templateName = template.name;  
// Result: "Article"

// STAP 3: Search ALL content items using this template (CRITICAL!)
const contentInstances = await sitecore_search({
  templateName: templateName,
  rootPath: '/sitecore/content',
  language: 'en',
  maxItems: 200
});

// STAP 4: Analyze content distribution
const sites = {};
const languages = {};
const locations = [];

contentInstances.forEach(item => {
  const siteName = item.path.split('/')[3];
  sites[siteName] = (sites[siteName] || 0) + 1;
  
  languages[item.language] = (languages[item.language] || 0) + 1;
  
  locations.push(item.path);
});

const stats = {
  totalItems: contentInstances.length,
  sites: sites,           // { MySite: 8, AnotherSite: 4 }
  languages: languages,   // { en: 10, nl: 2 }
  locations: locations
};
```

**Output:**
```
📋 Template: Article
  Path: /sitecore/templates/Feature/Articles/Article
  
📊 Usage Statistics:
  Total Content Items: 12
  
  By Site:
  - MySite: 8 items
  - AnotherSite: 4 items
  
  By Language:
  - en: 10 items
  - nl: 2 items
  
  Locations:
  - /sitecore/content/MySite/Home/Article1
  - /sitecore/content/MySite/News/Article2
  - /sitecore/content/MySite/Blog/Article3
  ... (12 total)
```

---

## 🎯 Complete Example: TestFeatures Module

### Scenario: Discover ALL TestFeatures Related Items

```typescript
// USER VRAAG: "Find everything related to TestFeatures"

// ==================================================
// FLOW A: Start met content item discovery
// ==================================================

// 1. Search content items with "TestFeatures" in name/path
const contentItems = await sitecore_search({
  searchText: 'TestFeatures',
  rootPath: '/sitecore/content',
  language: 'en',
  maxItems: 50
});

// Result: Found 3 content items
// - /sitecore/content/MySite/Home/TestItem1
// - /sitecore/content/MySite/Home/TestItem2
// - /sitecore/content/MySite/Features/TestItem3

// 2. Get first content item to analyze template
const firstItem = await sitecore_get_item({
  path: contentItems[0].path,
  language: 'en'
});

// firstItem.template.path = "/sitecore/templates/Feature/TestFeatures/TestFeature Item"
// firstItem.template.name = "TestFeature Item"

// 3. Search ALL content using same template (CRITICAL!)
const allTestFeatureContent = await sitecore_search({
  templateName: 'TestFeature Item',
  rootPath: '/sitecore/content',
  language: 'en',
  maxItems: 100
});

// Result: Found 12 items (not just the 3 with "TestFeatures" in name!)
// This discovers ALL content using this template, regardless of name

// ==================================================
// FLOW B: Template definition discovery
// ==================================================

// 4. Search template folder
const templates = await sitecore_search({
  rootPath: '/sitecore/templates/Feature/TestFeatures',
  language: 'en'
});

// Result: Found 5 templates
// - TestFeature Item
// - TestFeature Settings
// - TestFeature Data
// - _TestFeature Base
// - Data Templates/

// 5. For each template, search content usage (CRITICAL!)
for (const template of templates) {
  const templateUsage = await sitecore_search({
    templateName: template.name,
    rootPath: '/sitecore/content',
    language: 'en'
  });
  
  console.log(`Template "${template.name}" used by ${templateUsage.length} items`);
}

// Result:
// - TestFeature Item: 12 content items
// - TestFeature Settings: 1 content item
// - TestFeature Data: 0 content items (not used yet)
// - _TestFeature Base: 0 (base template, not directly instantiated)

// ==================================================
// Additional: Renderings and Resolvers
// ==================================================

// 6. Search renderings
const renderings = await sitecore_search({
  rootPath: '/sitecore/layout/Renderings/Feature/TestFeatures',
  language: 'en'
});

// 7. Search resolvers
const resolvers = await sitecore_search({
  rootPath: '/sitecore/system/Modules/Layout Service/Rendering Contents Resolvers/Feature/TestFeatures',
  language: 'en'
});
```

**Complete Output:**
```
🎯 TestFeatures Module - Complete Discovery

📄 Content Items (12 found):
  Using Template "TestFeature Item":
  - /sitecore/content/MySite/Home/TestItem1
  - /sitecore/content/MySite/Home/TestItem2
  - /sitecore/content/MySite/Features/TestItem3
  - /sitecore/content/MySite/Data/TestData1
  ... (12 total)
  
  Distribution:
  - MySite: 10 items
  - AnotherSite: 2 items
  
  Languages:
  - en: 10 items
  - nl: 2 items

📋 Templates (5 found):
  Location: /sitecore/templates/Feature/TestFeatures
  - TestFeature Item (used by 12 content items)
  - TestFeature Settings (used by 1 content item)
  - TestFeature Data (not used)
  - _TestFeature Base (base template)
  - Data Templates/

📊 Renderings (3 found):
  Location: /sitecore/layout/Renderings/Feature/TestFeatures
  - TestFeature List
  - TestFeature Detail
  - TestFeature Navigation

🔧 Resolvers (2 found):
  Location: /sitecore/system/.../Feature/TestFeatures
  - TestFeature List Resolver
  - TestFeature Detail Resolver

🔗 Helix Relationship Map:
  Feature Module: TestFeatures
  ├── Templates (5 items)
  │   └── Used by 13 content items total
  ├── Renderings (3 items)
  ├── Resolvers (2 items)
  └── Content Items (12 items)
      ├── 2 sites
      └── 2 languages
```

---

## ❌ Common Mistakes (AVOID!)

### ❌ FOUT 1: Alleen naam-based search
```typescript
// FOUT: Zoekt alleen items met "TestFeatures" in naam
const items = await sitecore_search({
  searchText: 'TestFeatures',
  rootPath: '/sitecore/content'
});
// Miss: Content items met andere namen maar zelfde template!
```

**✅ CORRECT:**
```typescript
// 1. Zoek met naam
const namedItems = await sitecore_search({
  searchText: 'TestFeatures',
  rootPath: '/sitecore/content'
});

// 2. Get template van eerste item
const item = await sitecore_get_item({ path: namedItems[0].path });

// 3. Zoek ALLE items met zelfde template
const allItems = await sitecore_search({
  templateName: item.template.name,
  rootPath: '/sitecore/content'
});
```

---

### ❌ FOUT 2: Template niet analyseren
```typescript
// FOUT: Stopt na content item vinden
const item = await sitecore_get_item({
  path: '/sitecore/content/MySite/TestItem'
});
// Miss: Geen related content, geen feature locations!
```

**✅ CORRECT:**
```typescript
// 1. Get item
const item = await sitecore_get_item({
  path: '/sitecore/content/MySite/TestItem'
});

// 2. Search related content (same template)
const related = await sitecore_search({
  templateName: item.template.name,
  rootPath: '/sitecore/content'
});

// 3. Search feature locations
const feature = item.template.path.split('/')[4];
const templates = await sitecore_search({
  rootPath: `/sitecore/templates/Feature/${feature}`
});
```

---

### ❌ FOUT 3: Template zonder content usage
```typescript
// FOUT: Template info zonder usage check
const template = await sitecore_get_template({
  templatePath: '/sitecore/templates/Feature/Articles/Article'
});
// Miss: Hoeveel content items gebruiken dit? Waar?
```

**✅ CORRECT:**
```typescript
// 1. Get template
const template = await sitecore_get_template({
  templatePath: '/sitecore/templates/Feature/Articles/Article'
});

// 2. Search ALL content using this template
const usage = await sitecore_search({
  templateName: template.name,
  rootPath: '/sitecore/content'
});

// 3. Analyze distribution
console.log(`Template used by ${usage.length} content items`);
```

---

## 📋 Checklist

Bij **ELKE** discovery taak:

### Content Item Discovery
- [ ] Content item gevonden?
- [ ] Template geanalyseerd?
- [ ] Alle content met zelfde template gezocht?
- [ ] Feature locaties onderzocht?
- [ ] Helix map gegenereerd?

### Template Discovery
- [ ] Template gevonden?
- [ ] Alle content instances gezocht?
- [ ] Usage statistics gegenereerd?
- [ ] Distribution geanalyseerd (sites, languages)?
- [ ] Related templates onderzocht (base templates)?

### Feature Module Discovery
- [ ] Templates onderzocht?
- [ ] Renderings onderzocht?
- [ ] Resolvers onderzocht?
- [ ] Content items gezocht (per template)?
- [ ] Complete Helix map?

---

## 🎓 Learning Examples

### Example 1: Article Feature
```typescript
// Given: Article content item
// Task: Find all related items

// Step 1: Content → Template
const article = await sitecore_get_item({
  path: '/sitecore/content/MySite/News/Article1'
});
// template: "Article", feature: "Articles"

// Step 2: Template → Related Content
const allArticles = await sitecore_search({
  templateName: 'Article',
  rootPath: '/sitecore/content'
});
// Result: 25 articles across 3 sites

// Step 3: Feature Locations
const articleTemplates = await sitecore_search({
  rootPath: '/sitecore/templates/Feature/Articles'
});
// Result: Article, Article List, Article Category templates

// Complete map generated!
```

---

### Example 2: Navigation Feature
```typescript
// Given: Navigation template
// Task: Find all navigation instances

// Step 1: Template → Content
const template = await sitecore_get_template({
  templatePath: '/sitecore/templates/Feature/Navigation/Navigation'
});

// Step 2: Search content usage
const navItems = await sitecore_search({
  templateName: 'Navigation',
  rootPath: '/sitecore/content'
});
// Result: 15 navigation items

// Step 3: Analyze distribution
const sites = groupBy(navItems, item => item.path.split('/')[3]);
// Result: { MySite: 8, AnotherSite: 5, ThirdSite: 2 }

// Usage report generated!
```

---

## 📚 Related Documentation

- **HELIX-RELATIONSHIP-DISCOVERY.md** - Complete Helix workflow
- **TESTFEATURES-MCP-WORKFLOW.md** - MCP tools workflow
- **.github/copilot-instructions.md** - AI assistant instructions
- **MCP-CONTEXT-INSTRUCTIONS.md** - Cross-IDE context

---

## ✅ Success Criteria

**You know you're doing it right when:**

✅ Content discovery ALTIJD includes template analysis  
✅ Template discovery ALTIJD includes content search  
✅ Related content wordt ALTIJD gevonden (via template)  
✅ Feature locations worden ALTIJD onderzocht  
✅ Usage statistics worden ALTIJD gegenereerd  
✅ Helix relationship maps zijn COMPLEET  
✅ Geen orphaned items (content without template check)  
✅ Geen incomplete discoveries (template without usage)

**Status: CRITICAL INSTRUCTION - ALWAYS FOLLOW** 🚀
