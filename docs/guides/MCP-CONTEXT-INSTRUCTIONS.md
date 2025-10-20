# MCP Context Instructions - Cross-IDE Guide

## 📋 Overzicht

Dit document legt uit hoe **context instructions** werken voor de Sitecore MCP Server in verschillende AI assistenten en IDE's.

## 🤖 Per AI Assistant / IDE

### 1. GitHub Copilot (VS Code)

**Instructie Bestand**: `.github/copilot-instructions.md`

**Hoe werkt het:**
- GitHub Copilot leest automatisch `.github/copilot-instructions.md` in je workspace
- Deze instructies zijn **altijd actief** tijdens Copilot Chat sessies
- Werkt **alleen** in VS Code met GitHub Copilot extensie

**Locatie in dit project:**
```
c:\gary\Sitecore\SitecoreMCP\.github\copilot-instructions.md
```

**Wat staat erin:**
- Smart language defaults (templates altijd 'en')
- Helix architecture awareness
- Template-based upward navigation
- Search > get_children preference
- GraphQL schema patterns
- Version management
- Field discovery rules

**Activatie:**
- ✅ Automatisch als je VS Code + GitHub Copilot gebruikt
- ❌ Geen effect in andere IDE's

---

### 2. JetBrains AI Assistant (Rider, IntelliJ, etc.)

**Instructie Bestand**: **GEEN EQUIVALENT**

**Hoe werkt het:**
- JetBrains AI Assistant heeft **geen** automatische instructie file
- Je moet context **handmatig** geven in de chat
- Alternatief: Custom prompts in AI Assistant settings

**Workaround Oplossingen:**

#### Optie A: Handmatig Context Geven
```
Bij elke chat sessie, start met:

"Ik werk met Sitecore MCP Server. Belangrijk:
- Templates zijn altijd in 'en' language
- Content kan meertalig zijn
- Voor meerdere items: gebruik sitecore_search, NIET sitecore_get_children
- Helix: navigeer via template naar Feature modules"
```

#### Optie B: Custom Prompt Template (Rider 2024.3+)
1. Open Rider Settings → Tools → AI Assistant → Custom Prompts
2. Maak nieuwe prompt: "Sitecore MCP Context"
3. Plak inhoud van `copilot-instructions.md`
4. Activeer via `/prompt sitecore` in chat

#### Optie C: Context File in Workspace
Maak `sitecore-mcp-context.md` in je project root:
```markdown
# Sitecore MCP Context

## Smart Language Defaults
- Templates/Renderings/System: ALTIJD 'en'
- Content items: 'en' als default

## Helix Navigation
- Content Item → Template → Feature Name → Search Paths
- Use sitecore_search, NOT sitecore_get_children
```

Dan: Attach file in AI Assistant chat (`@file sitecore-mcp-context.md`)

---

### 3. Claude Desktop

**Instructie Bestand**: **PER PROJECT VIA SYSTEM PROMPT**

**Hoe werkt het:**
- Claude Desktop heeft **geen** automatische instructie file
- Je kunt system prompt instellen in MCP server configuratie
- Of context geven in eerste bericht van conversatie

**Configuratie Oplossing:**

Voeg `systemPrompt` toe aan `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "sitecore": {
      "command": "node",
      "args": ["c:\\gary\\Sitecore\\SitecoreMCP\\dist\\index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_USERNAME": "admin",
        "SITECORE_PASSWORD": "jouw_wachtwoord"
      },
      "metadata": {
        "description": "Sitecore MCP Server with Helix awareness. Templates always use 'en' language. For multiple items use sitecore_search. Navigate via template to Feature modules."
      }
    }
  }
}
```

**Alternatief: Conversatie Starter**
Start elke nieuwe conversatie met:
```
Ik gebruik Sitecore MCP Server. Context:
- Templates/renderings: altijd 'en'
- Helix: navigeer via template naar Feature
- Meerdere items: gebruik search, niet get_children

[Je vraag hier...]
```

---

### 4. Cursor IDE

**Instructie Bestand**: `.cursorrules`

**Hoe werkt het:**
- Cursor leest automatisch `.cursorrules` in workspace root
- Vergelijkbaar met GitHub Copilot's `.github/copilot-instructions.md`

**Oplossing:**
Maak `.cursorrules` in project root:

```
# Sitecore MCP Server Rules

## Language Defaults
- Templates at /sitecore/templates/*: ALWAYS 'en'
- Renderings at /sitecore/layout/*: ALWAYS 'en'  
- System at /sitecore/system/*: ALWAYS 'en'
- Content at /sitecore/content/*: 'en' as default, unless specified

## Helix Architecture
- Navigate: Content Item → Template → Feature Name → Search Paths
- **BIDIRECTIONAL**: Content ↔ Template ↔ Related Content (both ways!)
- Content discovery → ALWAYS analyze template → Search related content
- Template discovery → ALWAYS search content → Find all instances
- Feature paths:
  - /sitecore/templates/Feature/{FeatureName}
  - /sitecore/layout/Renderings/Feature/{FeatureName}
  - /sitecore/system/Modules/.../Feature/{FeatureName}

## Multiple Items
- USE: sitecore_search (recursive, filters, sorting)
- AVOID: sitecore_get_children (direct children only)
```

---

### 5. Continue (VS Code Extension)

**Instructie Bestand**: `.continuerules` of `config.json`

**Hoe werkt het:**
- Continue kan custom instructions lezen
- Configureer in Continue settings

**Oplossing:**
1. Open Continue settings (Ctrl+Shift+P → "Continue: Open Config")
2. Voeg system message toe:

```json
{
  "systemMessage": "When using Sitecore MCP Server: Templates/renderings are always 'en'. Content can be multilingual. For multiple items use sitecore_search. Navigate via template to Feature modules in Helix architecture."
}
```

---

## 📊 Vergelijkingstabel

| AI Assistant | Auto Context File | Manual Context | Best Practice |
|--------------|-------------------|----------------|---------------|
| **GitHub Copilot** | ✅ `.github/copilot-instructions.md` | ❌ Niet nodig | Use auto file |
| **JetBrains AI** | ❌ Geen | ✅ Per chat | Custom prompt template |
| **Claude Desktop** | ❌ Geen | ✅ Conversatie start | Add to first message |
| **Cursor** | ✅ `.cursorrules` | ❌ Niet nodig | Use auto file |
| **Continue** | ⚠️ Config only | ✅ System message | Configure once |

---

## 🎯 Universele Context Template

Voor **alle** AI assistenten zonder auto-context file, gebruik dit template:

```markdown
# Sitecore MCP Server Context

## Language Rules
- `/sitecore/templates/*` → ALWAYS 'en'
- `/sitecore/layout/*` → ALWAYS 'en'
- `/sitecore/system/*` → ALWAYS 'en'
- `/sitecore/content/*` → 'en' as default

## Helix Architecture
**Template-Based Navigation:**
Content Item → Get Template → Extract Feature Name → Search Feature Paths

**Feature Paths:**
1. `/sitecore/templates/Feature/{FeatureName}`
2. `/sitecore/layout/Renderings/Feature/{FeatureName}`
3. `/sitecore/system/Modules/Layout Service/Rendering Contents Resolvers/Feature/{FeatureName}`

## Multiple Items
- ✅ USE: `sitecore_search` (recursive, filters, sorting, pagination)
- ❌ AVOID: `sitecore_get_children` (direct children only, no filters)

## Example Flow
```json
// A. Content → Template → Related Content (Upward)
// 1. Get content item
sitecore_get_item({ path: "/sitecore/content/MySite/TestItem" })

// 2. Extract feature from template.path
// "/sitecore/templates/Feature/TestFeatures/..." → "TestFeatures"

// 3. Search ALL content using same template (siblings/related)
sitecore_search({ 
  templateName: "TestFeature Item",
  rootPath: "/sitecore/content",
  language: "en" 
})

// 4. Search feature definition locations
sitecore_search({ 
  rootPath: "/sitecore/templates/Feature/TestFeatures",
  language: "en" 
})

// B. Template → Content (Downward)
// 1. Get template
sitecore_get_template({ 
  templatePath: "/sitecore/templates/Feature/TestFeatures/TestFeature Item" 
})

// 2. Search ALL content using this template
sitecore_search({ 
  templateName: "TestFeature Item",
  rootPath: "/sitecore/content",
  language: "en" 
})
```
```

---

## 💡 Aanbevelingen

### Voor GitHub Copilot Gebruikers
✅ **Geen actie nodig** - `.github/copilot-instructions.md` werkt automatisch

### Voor JetBrains Rider Gebruikers
1. **Optie 1**: Maak `sitecore-mcp-context.md` in project root
2. **Optie 2**: Custom prompt template in AI Assistant settings
3. **Optie 3**: Start elke chat met context block

### Voor Claude Desktop Gebruikers
1. Voeg `metadata.description` toe aan MCP config
2. Of start conversaties met context template

### Voor Cursor Gebruikers
1. Maak `.cursorrules` bestand in project root
2. Kopieer content van `.github/copilot-instructions.md`

### Voor Continue Gebruikers
1. Open Continue config
2. Voeg system message toe met Sitecore context

---

## 📝 Context File Aanmaken

### Voor Niet-Copilot IDE's

Maak dit bestand in je workspace: `SITECORE-MCP-CONTEXT.md`

```bash
# Windows PowerShell
cd c:\gary\Sitecore\SitecoreMCP
Copy-Item .github\copilot-instructions.md SITECORE-MCP-CONTEXT.md
```

Dan:
- **JetBrains**: `@file SITECORE-MCP-CONTEXT.md` in chat
- **Claude**: Eerste bericht van conversatie
- **Cursor**: Hernoem naar `.cursorrules`
- **Continue**: Kopieer naar config.json systemMessage

---

## 🔗 Gerelateerde Documentatie

- **Copilot-specific**: `.github/copilot-instructions.md`
- **MCP Tools**: `QUICK-REFERENCE.md`
- **Helix Workflows**: `HELIX-RELATIONSHIP-DISCOVERY.md`
- **User Guide**: `GEBRUIKERSHANDLEIDING.md`

---

## ✅ Samenvatting

| Vraag | Antwoord |
|-------|----------|
| Werkt `copilot-instructions.md` in Rider? | ❌ Nee, alleen in VS Code met GitHub Copilot |
| Hoe geef ik context in Rider? | Via custom prompt, @file attachment, of per chat |
| Hoe geef ik context in Claude Desktop? | Via metadata in config, of eerste bericht |
| Werkt het automatisch ergens anders? | ✅ Ja, in Cursor via `.cursorrules` |
| Moet ik elke keer context geven? | Afhankelijk van AI assistant (zie tabel) |

**Best Practice**: Voor consistente ervaring over alle IDE's, maak `SITECORE-MCP-CONTEXT.md` en reference waar nodig.
