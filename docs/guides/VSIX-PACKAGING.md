# VSIX Packaging voor Sitecore MCP Server

## Belangrijk

Dit project is een **standalone Model Context Protocol (MCP) server**, geen VS Code extensie. Het draait als een apart Node.js proces en communiceert via stdio met AI clients zoals:

- Claude Desktop
- VS Code GitHub Copilot
- JetBrains Rider AI Assistant
- Visual Studio 2022 GitHub Copilot

## Distributie Opties

### Optie 1: NPM Package (Aanbevolen)
Dit is de standaard manier voor MCP servers:

```bash
# Publiceer naar npm (eenmalig)
npm login
npm publish

# Gebruikers kunnen dan installeren via:
npm install -g sitecore-mcp-server
```

Configuratie in `claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "sitecore": {
      "command": "sitecore-mcp-server",
      "env": {
        "SITECORE_ENDPOINT": "https://your-instance/sitecore/api/graph/edge",
        "SITECORE_API_KEY": "your-api-key"
      }
    }
  }
}
```

### Optie 2: Git Repository Clone
Gebruikers clonen de repository en builden lokaal:

```bash
git clone https://github.com/GaryWenneker/sitecore-mcp-server
cd sitecore-mcp-server
npm install
npm run build
```

Configuratie wijst naar lokale build:
```json
{
  "mcpServers": {
    "sitecore": {
      "command": "node",
      "args": ["C:/path/to/sitecore-mcp-server/dist/index.js"],
      "env": {
        "SITECORE_ENDPOINT": "https://your-instance/sitecore/api/graph/edge",
        "SITECORE_API_KEY": "your-api-key"
      }
    }
  }
}
```

### Optie 3: Standalone Executable (Optional)
Gebruik `pkg` om een standalone executable te maken:

```bash
npm install -g pkg

# Windows
pkg . --targets node18-win-x64 --output sitecore-mcp-server.exe

# macOS
pkg . --targets node18-macos-x64 --output sitecore-mcp-server

# Linux
pkg . --targets node18-linux-x64 --output sitecore-mcp-server
```

Voeg toe aan `package.json`:
```json
{
  "bin": {
    "sitecore-mcp-server": "./dist/index.js"
  },
  "pkg": {
    "scripts": ["dist/**/*.js"],
    "targets": ["node18-win-x64", "node18-macos-x64", "node18-linux-x64"]
  }
}
```

## VSIX Is Niet Nodig

VSIX packages zijn specifiek voor VS Code extensies. Een MCP server:
- Draait als een extern proces
- Communiceert via stdio (stdin/stdout)
- Wordt geconfigureerd in AI client settings
- Is IDE-agnostisch

## Publicatie Checklist

### NPM Package
- [ ] Update versie in `package.json`
- [ ] Update CHANGELOG.md
- [ ] Commit en tag release: `git tag v1.1.0`
- [ ] Push tags: `git push --tags`
- [ ] Publiceer: `npm publish`

### GitHub Release
- [ ] Build project: `npm run build`
- [ ] Maak GitHub release met tag
- [ ] Attach `dist/` folder als artifact
- [ ] Documenteer installatie instructies in release notes

### Standalone Executable (Optional)
- [ ] Installeer pkg: `npm install -g pkg`
- [ ] Build executables voor alle platforms
- [ ] Test executables op target platforms
- [ ] Upload naar GitHub releases

## Publisher Info

- **Publisher**: Gary Wenneker
- **GitHub**: https://github.com/GaryWenneker
- **Blog**: https://www.gary.wenneker.org
- **LinkedIn**: https://www.linkedin.com/in/garywenneker/

## Licentie

MIT License - zie LICENSE file voor details.
