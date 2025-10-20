# Helix Relationship Discovery - MCP Best Practices

**Versie:** 1.5.0  
**Datum:** 17 oktober 2025  
**Doel:** Richtlijnen voor het ontdekken van relaties tussen Sitecore items volgens Helix architectuur  
**Referentie:** [Official Sitecore Helix Documentation](https://helix.sitecore.com/)

---

## 🎯 Overview

Wanneer gevraagd wordt naar **relaties tussen content items en hun data**, moet de MCP systematisch zoeken in de Helix-gestructureerde paden van Sitecore.

### Sitecore Helix Architectuur Principes

Helix is de **officiële best practice architectuur** voor Sitecore implementaties. Het definieert drie belangrijke topics:

1. **Dependencies** - Hoe features en functionaliteit in de solution met elkaar gerelateerd zijn
2. **Layers** - Controleert de richting van dependencies en zorgt voor een maintainable solution
3. **Modules** - Definieert isolatie van features en functionaliteit voor betere discoverability

**Common Closure Principle (CCP):**
> "Classes that change together are packaged together."

Dit principe zorgt ervoor dat changes in één feature GEEN changes veroorzaken in andere features.

---

## 📂 Helix Search Hierarchy

### 1. Content Items
**Pad:** `/sitecore/content`

**Wat vind je hier:**
- Site content (pages, articles, etc.)
- Meertalige content (en, nl, de, etc.)
- Data sources voor renderings
- Folders en organisatie structuur

**Helix Structuur:**
```
/sitecore/content/
  ├── [SiteName]/          # Project layer
  │   ├── Home
  │   ├── Articles/
  │   └── Data/            # Data sources (Feature layer data)
  ├── Global/              # Shared content
  └── Settings/            # Site-specific settings
```

**Zoek strategie:**
- Start bij rootPath (bijv. `/sitecore/content/MySite`)
- Gebruik `pathContains` filter voor specifieke folders
- Filter op `hasLayoutFilter: true` voor renderable pages
- Check `hasChildrenFilter: true` voor container items

---

### 2. Stable Dependencies Principle (SDP)

**Official Helix Principle:**
> "The dependencies between packages should be in the direction of the stability of the packages. A package should only depend upon packages that are more stable than it is."
> 
> Source: [Uncle Bob - Principles of OOD](http://butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod)

**Dependency Direction:**
```
Project Layer (UNSTABLE)
    ↓ (can depend on)
Feature Layer (STABLE)
    ↓ (can depend on)
Foundation Layer (MOST STABLE)
```

**Waarom belangrijk:**
- Unstable code mag NIET depended on worden door stable code
- Changes propageren alleen OMHOOG (naar unstable layers)
- Voorkomt onbedoelde side-effects in andere modules

### 3. Helix Architecture Awareness
**Pad:** `/sitecore/layout`

**Wat vind je hier:**
- Rendering definitions (Foundation/Feature/Project)
- Layout definitions
- Placeholder settings
- Device definitions

**Helix Structuur:**
```
/sitecore/layout/
  ├── Renderings/
  │   ├── Foundation/      # Basis renderings (header, footer, navigation)
  │   ├── Feature/         # Feature-specifieke renderings (article list, search)
  │   └── Project/         # Project-specifieke renderings
  ├── Layouts/
  │   └── [ProjectName]/   # Layout definitions per project
  └── Placeholder Settings/
```
