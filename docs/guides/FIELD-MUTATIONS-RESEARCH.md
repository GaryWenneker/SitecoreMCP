# Sitecore Field Mutations - Research & Implementation Plan

## Bevindingen

### GraphQL /items/master Endpoint
- ✅ **Query operations**: Volledig werkend
- ❌ **Mutation operations**: NIET beschikbaar in schema
- **Status**: Read-only GraphQL endpoint

### Test Resultaten
```powershell
# Test mutations.ps1 resultaten:
[TEST] updateItem - Field does not exist in schema
[TEST] updateItemField - Field does not exist in schema  
[TEST] setFieldValue - Field does not exist in schema
```

**Conclusie**: GraphQL /items/master endpoint ondersteunt GEEN field mutations via GraphQL syntax.

---

## Beschikbare Opties voor Field Mutations

### OPTIE 1: Sitecore Item Web API (SSC)
**Endpoint**: `/sitecore/api/ssc/item/{id}`

**Status**: ❌ 403 Forbidden met API key authenticatie

**Vermoedelijke oorzaak**:
- SSC API vereist andere authenticatie (username/password)
- SSC API is mogelijk niet enabled op deze instance
- SSC API heeft mogelijk andere URL pattern

**Code voorbeeld**:
```powershell
# Update field via SSC API
$headers = @{
    "Content-Type" = "application/json"
    # Mogelijk: Basic auth of cookies nodig
}

$body = @{
    ItemID = "{13DDF458-A0D2-482C-A3F1-0DF6BFCC2E36}"
    Language = "nl-NL"
    Fields = @(
        @{
            Name = "Title"
            Value = "New value"
        }
    )
} | ConvertTo-Json

Invoke-RestMethod -Uri "$baseUrl/sitecore/api/ssc/item/$itemId" `
    -Method PATCH `
    -Headers $headers `
    -Body $body
```

---

### ~~OPTIE 2: Sitecore PowerShell Extensions (SPE)~~ ❌ **BANNED - SECURITY RISK**

**⚠️ SPE IS NIET TOEGESTAAN**:
- ❌ **Security risk**: Remote code execution vulnerability
- ❌ **Attack vector**: Kan gebruikt worden voor malicious scripts
- ❌ **Not recommended**: Door Sitecore security best practices
- ❌ **Banned**: Mag NIET gebruikt worden in productie

**Alternative**: Gebruik Custom REST API (OPTIE 4) voor veilige field updates

---

### OPTIE 3: Sitecore Experience Editor API
**Endpoint**: `/sitecore/shell/Applications/WebEdit/WebEditPostRequest.aspx`

**Status**: ⚠️ Requires session cookies (browser authentication)

**Pros**:
- ✅ Official Sitecore UI mechanism
- ✅ Full field editing support

**Cons**:
- ❌ Requires browser session
- ❌ Complex authentication flow
- ❌ Not designed for programmatic access

---

### OPTIE 4: Custom REST API Endpoint
**Endpoint**: Custom controller in Sitecore solution

**Pros**:
- ✅ Full control over authentication
- ✅ Can use same API key as GraphQL
- ✅ Tailored to our needs

**Cons**:
- ⚠️ Requires deployment to Sitecore
- ⚠️ Need access to Sitecore solution code
- ⚠️ Maintenance overhead

**Code voorbeeld**:
```csharp
// Custom API Controller
[ApiController]
[Route("api/item")]
public class ItemFieldController : ControllerBase
{
    [HttpPatch("{itemId}/field")]
    public IActionResult UpdateField(
        string itemId,
        [FromBody] UpdateFieldRequest request)
    {
        // Validate API key
        var apiKey = Request.Headers["sc_apikey"];
        if (!ValidateApiKey(apiKey))
            return Unauthorized();
        
        // Get item
        var item = Sitecore.Context.Database
            .GetItem(new ID(itemId), 
                     Language.Parse(request.Language));
        
        if (item == null)
            return NotFound();
        
        // Update field
        using (new SecurityDisabler())
        {
            item.Editing.BeginEdit();
            item.Fields[request.FieldName].Value = request.Value;
            item.Editing.EndEdit();
        }
        
        return Ok(new { success = true });
    }
}
```

---

## Aanbevolen Oplossing

### Stap 1: Implementeer Custom REST API
Vraag Sitecore development team om custom endpoint:

```typescript
// src/index.ts - Add new MCP tool
{
  name: "sitecore_update_field",
  description: "Update a field value for a Sitecore item",
  inputSchema: {
    type: "object",
    properties: {
      path: { type: "string", description: "Item path" },
      itemId: { type: "string", description: "Item ID (alternative to path)" },
      language: { type: "string", description: "Language (nl-NL, en, etc.)" },
      fieldName: { type: "string", description: "Field name to update" },
      value: { type: "string", description: "New field value" }
    },
    required: ["language", "fieldName", "value"]
  }
}
```

---

## Alternatief: Item Web API met Correcte Auth

Test Item Web API met username/password:

```powershell
# Test Item Web API with Basic auth
$credentials = "$($env:SITECORE_USERNAME):$($env:SITECORE_PASSWORD)"
$encodedCreds = [Convert]::ToBase64String(
    [Text.Encoding]::ASCII.GetBytes($credentials))

$headers = @{
    "Authorization" = "Basic $encodedCreds"
    "Content-Type" = "application/json"
}

# Test GET first
$itemId = "{13DDF458-A0D2-482C-A3F1-0DF6BFCC2E36}"
$getUrl = "$baseUrl/sitecore/api/ssc/item/$itemId"

try {
    $item = Invoke-RestMethod -Uri $getUrl -Method GET -Headers $headers
    Write-Host "[OK] Item Web API works with Basic auth!"
    
    # Now try PATCH
    $updateBody = @{
        ItemID = $itemId
        Language = "nl-NL"
        Fields = @(
            @{
                Name = "Title"
                Value = "Updated via Item Web API"
            }
        )
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $getUrl `
        -Method PATCH `
        -Headers $headers `
        -Body $updateBody
    
    Write-Host "[OK] Field updated successfully!"
} catch {
    Write-Host "[FAIL] Item Web API: $($_.Exception.Message)"
}
```

---

## Test Resultaten

### Test 1: SPE Endpoint
```
✅ Script: test-spe-endpoint.ps1
❌ Result: 404 Not Found
📝 Conclusie: SPE is NIET geïnstalleerd (en mag ook niet - security risk!)
⚠️ STATUS: SPE IS BANNED - Gebruik NIET in productie
```

### Test 2: Item Web API
```
✅ Script: test-item-web-api-auth.ps1
❌ Result: 403 Forbidden (met Basic auth)
📝 Conclusie: Item Web API is niet enabled of vereist andere configuratie
```

### Conclusie Tests
**GEEN van de veilige standaard Sitecore mutation APIs is beschikbaar:**
- ❌ GraphQL /items/master: Read-only, geen mutations
- ❌ Item Web API: Niet enabled/configured
- ⚠️ SPE (Sitecore PowerShell Extensions): BANNED - Security risk, mag niet gebruikt worden

---

## Volgende Stappen

### OPTIE A: Custom REST API (Aanbevolen)
**Voordeel**: Volledige controle, kan zelfde API key authentication gebruiken als GraphQL

**Implementatie**:
1. ✅ **Vraag Sitecore developers** om custom REST API endpoint toe te voegen
2. ⏳ **Endpoint specificatie**:
   ```
   POST /api/item/field
   Headers:
     - sc_apikey: [API_KEY]
   Body:
     {
       "itemId": "{GUID}",
       "path": "/sitecore/content/...",  // Optional alternative to itemId
       "language": "nl-NL",
       "fieldName": "Title",
       "value": "New value"
     }
   ```
3. ⏳ **Deploy naar Sitecore instance**
4. ⏳ **Test endpoint**
5. ⏳ **Implementeer MCP tool**

### OPTIE B: Enable Item Web API
**Voordeel**: Standaard Sitecore functionaliteit, geen custom code

**Implementatie**:
1. ✅ **Vraag Sitecore administrators** om Item Web API te enablen
2. ⏳ **Configureer permissions** voor de API key user
3. ⏳ **Test met test-item-web-api-auth.ps1**
4. ⏳ **Implementeer MCP tool**

### ~~OPTIE C: Enable SPE~~ ❌ **BANNED - NIET GEBRUIKEN**
**Status**: **SECURITY RISK - MAG NIET GEBRUIKT WORDEN**

**Waarom banned**:
- ❌ Remote code execution vulnerability
- ❌ Attack vector voor malicious scripts
- ❌ Niet goedgekeurd door security team
- ❌ Sitecore best practice: SPE remote scripting disabled in productie

**Alternative**: Gebruik OPTIE A (Custom REST API)

---

## Aanbeveling

**BESTE OPLOSSING: Custom REST API (OPTIE A)**

**Redenen**:
1. ✅ Kan zelfde API key authentication gebruiken als GraphQL
2. ✅ Geen extra modules/configuratie nodig
3. ✅ Volledige controle over validatie en error handling
4. ✅ Kan geoptimaliseerd worden voor MCP use cases
5. ✅ Veiligheid: Expliciete permissions per field/item type

**Vereist**:
- Contact met Sitecore development team
- Deployment van custom controller naar Sitecore solution
- Update van API key permissions (als nodig)

**Code voorbeeld custom controller**: Zie boven in document

---

## Volgende Stappen

1. ✅ **Test SPE beschikbaarheid** → ❌ Niet beschikbaar
2. ✅ **Test Item Web API met Basic auth** → ❌ Niet enabled
3. ⏳ **Contact Sitecore team** → Vraag om custom REST API of enable Item Web API
4. ⏳ **Implementeer werkende oplossing** → MCP tool toevoegen na API beschikbaar
5. ⏳ **Update documentatie** → MCP tools guide
6. ⏳ **Test end-to-end** → Field update via Claude Desktop

---

## Samenvatting

**Probleem**: Het "Title" veld kan niet worden geüpdatet via GraphQL /items/master endpoint omdat deze read-only is.

**Veilige Oplossingen**:
1. **Custom REST API** - Vereist deployment, meest veilig en flexibel
2. **Item Web API met Basic auth** - RESTful, vereist username/password

**Banned**:
- ❌ **SPE (Sitecore PowerShell Extensions)** - Security risk, mag NIET gebruikt worden

**Aanbeveling**: Gebruik Custom REST API (OPTIE 1/A) voor veilige field mutations.

**MCP Implementation**: Voeg `sitecore_update_field` tool toe die SPE of Item Web API gebruikt voor field mutations.
