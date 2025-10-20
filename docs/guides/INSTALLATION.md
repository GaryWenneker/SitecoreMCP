# Sitecore MCP Server - Installation Instructions

## Step 1: Sitecore PowerShell Extensions Configuration

### Check SPE Installation
1. Go to your Sitecore instance: `https://your-sitecore-instance.com/sitecore`
2. Log in with admin credentials
3. Go to: `/sitecore/system/Modules/PowerShell/Script Library`
4. If this folder exists, SPE is installed

### Enable SPE Remoting API (IMPORTANT!)

**Note**: You must enable TWO things:

#### 1. Enable restfulv2 service
Edit: `App_Config\Include\Spe\Spe.config` or `Spe.Services.config`

Add or modify:
```xml
<spe>
  <services>
    <restfulv2 enabled="true">
      <authorization>
        <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
        <add Permission="Allow" IdentityType="Role" Identity="sitecore\PowerShell Extensions Remoting" />
      </authorization>
    </restfulv2>
  </services>
</spe>
```

#### 2. Enable remoting
In the same file:
```xml
<spe>
  <remoting enabled="true" requireSecureConnection="false">
    <authorization>
      <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
      <add Permission="Allow" IdentityType="Role" Identity="sitecore\PowerShell Extensions Remoting" />
    </authorization>
  </remoting>
</spe>
```

See [SPE-CONFIGURATION.md](SPE-CONFIGURATION.md) for a complete configuration example.

#### 3. Restart Sitecore
```powershell
iisreset
```

### Test SPE API
Open PowerShell and test the API:
```powershell
$headers = @{
    "Content-Type" = "text/plain"
}

$script = "Get-Item -Path 'master:\sitecore\content' | Select-Object Name, ID, Path | ConvertTo-Json"

$response = Invoke-WebRequest `
    -Uri "https://your-sitecore-instance.com/sitecore/api/spe/v2/script?sc_database=master&user=admin&password=your_password" `
    -Method Post `
    -Headers $headers `
    -Body $script `
    -UseBasicParsing

$response.Content
```

## Step 2: MCP Server Configuration

### Create .env file
```bash
cd c:\gary\Sitecore\SitecoreMCP
copy .env.example .env
```

Edit `.env`:
```env
SITECORE_HOST=https://your-sitecore-instance.com
SITECORE_USERNAME=admin
SITECORE_PASSWORD=your_password
```

## Step 3: MCP Client Configuration

### Option A: Claude Desktop

#### Configuration file location
Windows: `%APPDATA%\Claude\claude_desktop_config.json`

#### Add Sitecore MCP
```json
{
  "mcpServers": {
    "sitecore": {
      "command": "node",
      "args": ["c:\\gary\\Sitecore\\SitecoreMCP\\dist\\index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_USERNAME": "admin",
        "SITECORE_PASSWORD": "your_password"
      }
    }
  }
}
```

#### Restart Claude Desktop
Close Claude Desktop completely and restart.

---

### Option B: VS Code with GitHub Copilot

#### Requirements
- VS Code installed
- GitHub Copilot extension active

#### Configuration
1. Open VS Code Settings (Ctrl+,)
2. Search for "MCP" or "Model Context Protocol"
3. Or edit `settings.json` directly (Ctrl+Shift+P → "Preferences: Open User Settings (JSON)")

```json
{
  "github.copilot.chat.mcp.servers": {
    "sitecore": {
      "command": "node",
      "args": ["c:\\gary\\Sitecore\\SitecoreMCP\\dist\\index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_USERNAME": "admin",
        "SITECORE_PASSWORD": "your_password"
      }
    }
  }
}
```

#### Usage in VS Code
1. Open Copilot Chat (Ctrl+Alt+I)
2. Use @ to activate MCP tools
3. Type for example: `@workspace Get the Home item from Sitecore: /sitecore/content/Home`

**Context Instructions**: VS Code with GitHub Copilot automatically reads `.github/copilot-instructions.md` for Sitecore-specific best practices (smart language defaults, Helix awareness, etc.)

#### Alternative: Workspace Settings
For project-specific configuration, create `.vscode/settings.json` in your workspace:

```json
{
  "github.copilot.chat.mcp.servers": {
    "sitecore": {
      "command": "node",
      "args": ["${workspaceFolder}\\..\\SitecoreMCP\\dist\\index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_USERNAME": "admin",
        "SITECORE_PASSWORD": "your_password"
      }
    }
  }
}
```

---

### Option C: JetBrains Rider

#### Requirements
- Rider 2024.3 or newer
- AI Assistant plugin installed

#### Configuration
1. Open Rider Settings (Ctrl+Alt+S)
2. Go to: `Tools → AI Assistant → Model Context Protocol`
3. Or edit the configuration file directly:

**Windows**: `%APPDATA%\JetBrains\Rider2024.3\options\mcp-servers.json`

```json
{
  "mcpServers": {
    "sitecore": {
      "command": "node",
      "args": ["c:\\gary\\Sitecore\\SitecoreMCP\\dist\\index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_USERNAME": "admin",
        "SITECORE_PASSWORD": "your_password"
      }
    }
  }
}
```

#### Usage in Rider
1. Open AI Assistant window (Alt+1 or via View menu)
2. Use the chat interface
3. The Sitecore MCP tools are automatically available
4. Type for example: `Get the Home item from Sitecore`

**Note**: JetBrains AI Assistant does **not** have automatic context file like GitHub Copilot's `copilot-instructions.md`. For Sitecore-specific context, see [MCP-CONTEXT-INSTRUCTIONS.md](MCP-CONTEXT-INSTRUCTIONS.md) for workarounds.

#### Project-specific configuration
Create `.idea/mcp-servers.json` in your project root:

```json
{
  "mcpServers": {
    "sitecore": {
      "command": "node",
      "args": ["${PROJECT_DIR}/../SitecoreMCP/dist/index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_USERNAME": "admin",
        "SITECORE_PASSWORD": "your_password"
      }
    }
  }
}
```

---

### Option D: Visual Studio 2022

#### Requirements
- Visual Studio 2022 version 17.8 or newer
- GitHub Copilot extension installed

#### Configuration Method 1: Via Extension Settings
1. Open Visual Studio
2. Go to: `Extensions → GitHub Copilot → Settings`
3. Search for "Model Context Protocol"
4. Add Sitecore MCP server

#### Configuration Method 2: Via Configuration File
Edit or create: `%USERPROFILE%\.github-copilot\mcp-servers.json`

```json
{
  "mcpServers": {
    "sitecore": {
      "command": "node",
      "args": ["c:\\gary\\Sitecore\\SitecoreMCP\\dist\\index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_USERNAME": "admin",
        "SITECORE_PASSWORD": "your_password"
      }
    }
  }
}
```

#### Solution-specific configuration
Create `.vs/mcp-servers.json` in your solution folder:

```json
{
  "mcpServers": {
    "sitecore": {
      "command": "node",
      "args": ["$(SolutionDir)\\..\\SitecoreMCP\\dist\\index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_USERNAME": "admin",
        "SITECORE_PASSWORD": "your_password"
      }
    }
  }
}
```

#### Usage in Visual Studio
1. Open Copilot Chat window (View → Other Windows → GitHub Copilot Chat)
2. Or use shortcut: `Ctrl+/`
3. Use # to add context
4. Type for example: `#sitecore Get item: /sitecore/content/Home`

---

### Option E: Cursor IDE

#### Requirements
- Cursor installed (based on VS Code)
- Built-in AI assistant (no extra extensions needed)

#### Configuration
Edit: `%APPDATA%\Cursor\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json`

Or via Cursor Settings:
1. Open Settings (Ctrl+,)
2. Search for "MCP" or "Model Context Protocol"
3. Or edit `settings.json` directly

```json
{
  "mcpServers": {
    "sitecore": {
      "command": "node",
      "args": ["c:\\gary\\Sitecore\\SitecoreMCP\\dist\\index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_USERNAME": "admin",
        "SITECORE_PASSWORD": "your_password"
      }
    }
  }
}
```

#### Usage in Cursor
1. Open Cursor Chat (Ctrl+L)
2. Or use Composer (Ctrl+Shift+L) for multi-file editing
3. Type for example: "Get the Home item from Sitecore: /sitecore/content/Home"
4. Cursor's AI automatically uses the Sitecore MCP tools

**Context File**: Cursor supports `.cursorrules` in workspace root. See [MCP-CONTEXT-INSTRUCTIONS.md](MCP-CONTEXT-INSTRUCTIONS.md)

---

### Option F: Continue (VS Code Extension)

#### Requirements
- VS Code installed
- Continue extension: `continue.continue`

#### Configuration
1. Open Command Palette (Ctrl+Shift+P)
2. "Continue: Open Config"
3. Or edit: `%USERPROFILE%\.continue\config.json`

```json
{
  "mcpServers": [
    {
      "name": "sitecore",
      "command": "node",
      "args": ["c:\\gary\\Sitecore\\SitecoreMCP\\dist\\index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_USERNAME": "admin",
        "SITECORE_PASSWORD": "your_password"
      }
    }
  ],
  "systemMessage": "When using Sitecore MCP: Templates/renderings are always 'en'. Content can be multilingual. For multiple items use sitecore_search. Navigate via template to Feature modules."
}
```

#### Usage in Continue
1. Open Continue sidebar (Ctrl+Shift+L)
2. Type your question about Sitecore
3. Continue automatically uses the MCP tools

---

### Option G: Windsurf IDE

#### Requirements
- Windsurf installed (AI-first code editor)
- Built-in Claude/GPT-4 integration

#### Configuration
Edit: `%APPDATA%\Windsurf\User\settings.json`

Or via Windsurf Settings:
1. Open Settings (Ctrl+,)
2. Search for "MCP Servers"
3. Add MCP Server configuration

```json
{
  "windsurf.mcp.servers": {
    "sitecore": {
      "command": "node",
      "args": ["c:\\gary\\Sitecore\\SitecoreMCP\\dist\\index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_USERNAME": "admin",
        "SITECORE_PASSWORD": "your_password"
      }
    }
  }
}
```

#### Usage in Windsurf
1. Open Windsurf Chat (Ctrl+K)
2. Or use Cascade mode (Ctrl+Shift+K) for autonomous editing
3. Type for example: "Show me the Home item from /sitecore/content/Home"

---

### Option H: Zed Editor

#### Requirements
- Zed installed (high-performance collaborative editor)
- AI assistant enabled

#### Configuration
Edit: `%APPDATA%\Zed\settings.json`

Or via Zed Settings:
1. Open Command Palette (Ctrl+Shift+P)
2. "zed: open settings"
3. Add MCP configuration

```json
{
  "context_servers": {
    "sitecore": {
      "command": "node",
      "args": ["c:\\gary\\Sitecore\\SitecoreMCP\\dist\\index.js"],
      "env": {
        "SITECORE_HOST": "https://your-sitecore-instance.com",
        "SITECORE_USERNAME": "admin",
        "SITECORE_PASSWORD": "your_password"
      }
    }
  }
}
```

#### Usage in Zed
1. Open Assistant panel (Ctrl+?)
2. MCP tools are automatically available
3. Type for example: "Get Sitecore item /sitecore/content/Home"

---

### Option I: Neovim (with Avante plugin)

#### Requirements
- Neovim 0.10+ installed
- `yetone/avante.nvim` plugin
- Node.js in PATH

#### Configuration
Add to your Neovim config (`~/.config/nvim/lua/plugins/avante.lua` or `init.lua`):

```lua
return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  opts = {
    provider = "claude", -- or "openai", "copilot"
    mcp_servers = {
      sitecore = {
        command = "node",
        args = { "c:\\gary\\Sitecore\\SitecoreMCP\\dist\\index.js" },
        env = {
          SITECORE_HOST = "https://your-sitecore-instance.com",
          SITECORE_USERNAME = "admin",
          SITECORE_PASSWORD = "your_password"
        }
      }
    }
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
}
```

#### Usage in Neovim
1. Open Avante: `:AvanteAsk`
2. Or keybinding: usually `<leader>aa`
3. Type for example: "Get item from /sitecore/content/Home"

---

### Option J: Emacs (with gptel)

#### Requirements
- Emacs 29+ installed
- `gptel` package
- MCP support via shell-command integration

#### Configuration
Add to your Emacs config (`~/.emacs.d/init.el`):

```elisp
;; MCP Server wrapper function
(defun sitecore-mcp-query (query)
  "Execute Sitecore MCP query"
  (interactive "sQuery: ")
  (let ((process-environment
         (cons "SITECORE_HOST=https://your-sitecore-instance.com"
         (cons "SITECORE_USERNAME=admin"
         (cons "SITECORE_PASSWORD=your_password"
               process-environment)))))
    (shell-command
     (format "node c:\\gary\\Sitecore\\SitecoreMCP\\dist\\index.js -q '%s'" query)
     "*Sitecore MCP*")))

;; Keybinding
(global-set-key (kbd "C-c s") 'sitecore-mcp-query)
```

**Note**: Emacs has limited native MCP support. The above is a workaround via shell commands.

---

### Configuration Overview

| IDE/Tool | Config Location | Verification |
|----------|----------------|-------------|
| **Claude Desktop** | `%APPDATA%\Claude\claude_desktop_config.json` | Restart app + test chat |
| **VS Code (Copilot)** | `.vscode/settings.json` or User settings | Reload window (Ctrl+Shift+P) |
| **Rider** | `%APPDATA%\JetBrains\Rider2024.3\options\mcp-servers.json` | Restart IDE |
| **Visual Studio** | `%USERPROFILE%\.github-copilot\mcp-servers.json` | Restart solution |
| **Cursor** | `%APPDATA%\Cursor\User\globalStorage\...\cline_mcp_settings.json` | Reload window |
| **Continue** | `%USERPROFILE%\.continue\config.json` | Extension reload |
| **Windsurf** | `%APPDATA%\Windsurf\User\settings.json` | IDE restart |
| **Zed** | `%APPDATA%\Zed\settings.json` | Automatic reload |
| **Neovim (Avante)** | `~/.config/nvim/lua/plugins/avante.lua` | `:source %` + restart |
| **Emacs (gptel)** | `~/.emacs.d/init.el` | `M-x eval-buffer` |

## Step 4: Test the Integration

### In Claude Desktop
1. Start a new conversation
2. Type: "Get the Home item: /sitecore/content/Home"
3. Claude should now use the Sitecore MCP

### In VS Code
1. Open Copilot Chat (Ctrl+Alt+I)
2. Type: "Get the Home item: /sitecore/content/Home"
3. Copilot automatically uses the Sitecore MCP tools

### In Rider
1. Open AI Assistant (Alt+1)
2. Type: "Get the Home item: /sitecore/content/Home"
3. Rider's AI Assistant uses the MCP server

### In Visual Studio
1. Open Copilot Chat (Ctrl+/)
2. Type: "#sitecore Get the Home item: /sitecore/content/Home"
3. Visual Studio Copilot uses the configuration

### In Cursor
1. Open Cursor Chat (Ctrl+L)
2. Type: "Get the Home item: /sitecore/content/Home"
3. Cursor AI uses the MCP tools

### In Continue
1. Open Continue sidebar (Ctrl+Shift+L)
2. Type: "Get Sitecore item /sitecore/content/Home"
3. Continue uses the configuration

### In Windsurf
1. Open Windsurf Chat (Ctrl+K)
2. Type: "Show me /sitecore/content/Home"
3. Windsurf uses the MCP server

### In Zed
1. Open Assistant panel (Ctrl+?)
2. Type: "Get item /sitecore/content/Home"
3. Zed uses the context server

### In Neovim
1. Run `:AvanteAsk`
2. Type: "Get /sitecore/content/Home"
3. Avante uses the MCP server

### Example queries
```
1. Get item:
   "Show me the properties of /sitecore/content/Home"

2. Get children:
   "Show all children of /sitecore/content/Home"

3. Search items:
   "Search for all items with 'contact' in the name"

4. Execute query:
   "Execute this query: /sitecore/content/Home//*[@@templatename='Sample Item']"

5. Get field value:
   "What is the Title field of /sitecore/content/Home?"
```

## Troubleshooting

### "Connection refused" error
- Check if Sitecore is running
- Verify the hostname in .env
- Check SSL certificate (for local dev self-signed is OK)

### "Authentication failed"
- Verify username/password in .env
- Check if the user has rights for SPE
- Look in Sitecore logs: `/sitecore/admin/showlog.aspx`

### "PowerShell execution failed"
- Check SPE configuration in `Spe.config`
- Verify that remoting is enabled
- Test the API endpoint directly with Postman

### MCP Server doesn't appear
**Claude Desktop:**
- Check `claude_desktop_config.json` syntax
- Verify path to `index.js` is correct
- Look in logs: `%APPDATA%\Claude\logs`
- Restart Claude Desktop completely

**VS Code:**
- Check `settings.json` syntax
- Reload window: Ctrl+Shift+P → "Developer: Reload Window"
- Check Output panel: "GitHub Copilot Chat"
- Update GitHub Copilot extension

**Rider:**
- Check `mcp-servers.json` syntax  
- Invalidate caches: File → Invalidate Caches / Restart
- Check Event Log for errors
- Update AI Assistant plugin

**Visual Studio:**
- Check `mcp-servers.json` syntax
- Close all Visual Studio instances
- Restart as Administrator
- Check Extension logs

**Cursor:**
- Check config syntax in Cursor settings
- Reload window: Cmd/Ctrl+Shift+P → "Developer: Reload Window"
- Check Cursor logs: Help → Show Logs
- Update Cursor to latest version

**Continue:**
- Check `config.json` syntax
- Reload Continue extension: Disable/Enable in Extensions panel
- Check Continue output panel
- Update Continue extension

**Windsurf:**
- Check settings.json syntax
- Restart Windsurf IDE
- Check Windsurf logs (Help → Toggle Developer Tools)
- Verify Node.js is in PATH

**Zed:**
- Check settings.json syntax
- Zed reloads automatically, but try reopening workspace
- Check Zed diagnostics panel
- Ensure latest Zed version

**Neovim:**
- Check Lua syntax in config
- Run `:checkhealth avante` for diagnostics
- Verify Node.js accessible: `:!node --version`
- Update Avante plugin: `:Lazy update`

**Emacs:**
- Check Elisp syntax: `M-x check-parens`
- Eval buffer: `M-x eval-buffer`
- Check *Messages* buffer for errors
- Verify shell-command works: `M-x shell-command node --version`

### Items not found
- Verify that path exists in Sitecore
- Check database (master/web)
- Check language (en/nl)
- Test query first in Sitecore PowerShell ISE

## Advanced Configuration

### Other Database
All tools accept a `database` parameter:
- `master` (default)
- `web`
- `core`

### Other Language
All tools accept a `language` parameter:
- `en` (default)
- `nl`
- `de`
- etc.

### Custom Queries
The `sitecore_query` tool supports Sitecore fast query syntax:
```
/sitecore/content/Home//*[@@templatename='Article']
/sitecore/content//*[@Title='Home']
/sitecore/content/Home/*[@@name='*contact*']
```

## Logging & Debugging

### MCP Server Logs
The server logs to stderr, visible in Claude Desktop logs.

### Sitecore Logs
Check: `https://your-sitecore-instance.com/sitecore/admin/showlog.aspx`

### PowerShell ISE
Test scripts in Sitecore PowerShell ISE:
`/sitecore/system/Modules/PowerShell/Script Library`

## Security

⚠️ **Note**: This configuration is for LOCAL development!

For production:
1. Use HTTPS with valid certificate
2. No credentials in config files
3. Use Sitecore API keys
4. Restrict SPE permissions
5. Enable SSL certificate verification in code
