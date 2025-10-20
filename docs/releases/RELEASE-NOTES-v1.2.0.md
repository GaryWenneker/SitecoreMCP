# Release Notes v1.2.0 - Slash Command Menu

**Release Date**: [Current Date]  
**Version**: 1.2.0  
**Author**: Gary Wenneker

## 🎉 What's New

### ⚡ Slash Command Menu Integration

De grootste feature van deze release is de **Slash Command Menu** integratie! Nu kun je `/` typen in je AI chat interface om direct toegang te krijgen tot Sitecore commando's.

#### Features
- 🔧 **`/sitecore` slash command** - Verschijnt in het menu wanneer je `/` typt
- 🎯 **Smart Auto-wrapping** - Geen prefix nodig, `/sitecore` wordt automatisch toegevoegd
- 💡 **Command Suggestions** - Zie een duidelijke beschrijving in het menu
- 🌐 **Multi-Client Support** - Werkt in Claude Desktop, VS Code, en andere MCP clients

#### How It Works

**Before v1.2.0** (Still works):
```
/sitecore get item /sitecore/content/Home
/sitecore search articles
```

**NEW in v1.2.0** (Slash Command Menu):
```
1. Type / in chat
2. Select "🔧 /sitecore - Sitecore command interface" from menu
3. Type your command: "get item /sitecore/content/Home"
   (No /sitecore prefix needed!)
```

### Technical Implementation

#### MCP Prompts Capability
- Added `prompts: {}` capability to MCP server
- Implemented `ListPromptsRequestSchema` handler
- Implemented `GetPromptRequestSchema` handler
- Prompt automatically wraps user input with `/sitecore` prefix

#### Code Changes
**src/index.ts**:
- Line 5-9: New imports for prompt schemas
- Line 37: Version bumped to 1.2.0
- Line 43: Added prompts capability
- Lines 48-87: Prompt handlers implementation

**Prompt Definition**:
```typescript
{
  name: "sitecore",
  description: "🔧 Sitecore command interface - Type natural language commands",
  arguments: [{
    name: "command",
    description: "Your Sitecore command (e.g., 'get item /path', 'search articles', 'help')",
    required: false
  }]
}
```

## 📝 Documentation Updates

### New Files
- **SLASH-COMMAND.md** (400+ lines) - Complete slash command documentation
  - How it works
  - Usage examples for different clients
  - Troubleshooting guide
  - Pro tips and best practices

### Updated Files
- **README.md** - Added slash command examples and documentation links
- **package.json** - Version bumped to 1.2.0, updated description
- **src/index.ts** - Version 1.2.0, prompts capability added

## 🎯 User Experience Improvements

### Discoverability
Previously, users needed to **know** the `/sitecore` command existed. Now:
- Type `/` → See all available commands
- Select `/sitecore` from menu
- Get helpful description and argument hints

### Ease of Use
- **No more prefix confusion** - Auto-wrapping handles the `/sitecore` prefix
- **Consistent UX** - Same slash command experience across all MCP clients
- **Helpful prompts** - Command argument shows examples

### Compatibility
- ✅ Claude Desktop
- ✅ VS Code with GitHub Copilot
- ✅ Any MCP-compatible client that supports prompts capability

## 🔧 Technical Details

### MCP Protocol
Uses the **MCP Prompts** capability, which is separate from Tools:
- **Tools**: Execute actions (like `sitecore_get_item`)
- **Prompts**: Provide discoverable entry points in chat UI

### Integration Flow
```
User types /
  → Client shows slash command menu
  → User selects /sitecore
  → User enters command (e.g., "help")
  → GetPromptRequestSchema handler wraps it: "/sitecore help"
  → Passes to existing sitecore_command tool
  → Natural language parser processes it
  → Returns formatted markdown result
```

### Backward Compatibility
All existing functionality still works:
- Direct `/sitecore` commands still supported
- All 10 MCP tools unchanged
- Natural language parser unchanged (15+ patterns)
- Output formatting unchanged (10 emoji types)
