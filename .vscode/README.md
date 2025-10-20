# VS Code Workspace Configuratie

Deze folder bevat VS Code specifieke instellingen voor het SitecoreMCP project.

## settings.json

Bevat de GitHub Copilot MCP server configuratie die automatisch wordt geladen wanneer je dit project opent in VS Code.

## Gebruik

1. Open dit project in VS Code
2. Zorg dat de MCP server is gebouwd: `npm run build`
3. Reload Window: `Ctrl+Shift+P` → "Developer: Reload Window"
4. Open Copilot Chat: `Ctrl+Alt+I`
5. Test met: "Haal het Home item op uit Sitecore: /sitecore/content/Home"

## Configuratie aanpassen

Pas `settings.json` aan om:
- Je eigen Sitecore hostname in te stellen
- Credentials te wijzigen
- Database of language defaults aan te passen

⚠️ **Let op**: Voeg `settings.json` toe aan `.gitignore` als het gevoelige credentials bevat!
