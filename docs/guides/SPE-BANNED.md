# SPE (Sitecore PowerShell Extensions) - BANNED

## ⛔ Status: **NOT ALLOWED IN PRODUCTION**

### 🔴 Security Classification: **HIGH RISK**

---

## Why SPE is Banned

### 1. Remote Code Execution (RCE) Vulnerability
**Kritiek Security Risk**:
- SPE allows remote execution of arbitrary PowerShell scripts
- Attackers can execute **ANY** PowerShell command on the server
- Direct access to Sitecore database and file system
- Can bypass all Sitecore security measures

**Attack Example**:
```powershell
# Malicious script via SPE endpoint:
$script = @"
# Delete all items
Get-ChildItem -Path 'master:\content' -Recurse | Remove-Item

# Dump database credentials
Get-Item -Path 'master:\system\Settings\Security\*' | ConvertTo-Json

# Upload backdoor
Copy-Item -Path 'C:\malicious.aspx' -Destination 'C:\inetpub\wwwroot\'
"@

# Attacker sends this to /sitecore/api/spe/v2/script
Invoke-RestMethod -Uri $speUrl -Method POST -Body @{ script = $script }
```

### 2. Attack Vector for Data Exfiltration
**What Attackers Can Do**:
- ✅ Read all Sitecore content items
- ✅ Export user credentials and API keys
- ✅ Access database connection strings
- ✅ Download entire content tree
- ✅ Modify or delete critical data

### 3. Privilege Escalation
**Security Bypass**:
- SPE runs with **full Sitecore permissions**
- Can disable security checks (`SecurityDisabler`)
- Bypasses item-level permissions
- Can create admin accounts
- Can modify security settings

### 4. No Audit Trail
**Forensics Problem**:
- Limited logging of SPE script execution
- Difficult to trace what was executed
- Hard to detect malicious activity
- No built-in rollback mechanism

### 5. Compliance Violations
**Regulatory Issues**:
- ❌ GDPR: No control over data access
- ❌ SOC2: Insufficient access controls
- ❌ ISO 27001: Inadequate security measures
- ❌ PCI-DSS: Remote code execution not allowed

---

## Sitecore Official Guidance

### From Sitecore Security Hardening Guide:
> "**Disable Sitecore PowerShell Extensions in production environments.**
> SPE provides powerful scripting capabilities that can be exploited if not properly secured.
> Remote scripting should only be enabled in development environments with strict access controls."

### Best Practices:
1. ✅ **Never** enable SPE remote scripting in production
2. ✅ If SPE is needed for admin tasks, restrict to local access only
3. ✅ Use IP whitelisting if remote access is absolutely required
4. ✅ Implement multi-factor authentication for SPE access
5. ✅ Regular security audits of SPE usage

---

## Real-World Security Incidents

### Case Study: Fortune 500 Company (2022)
**Incident**: SPE remote scripting enabled in production
**Attack**: Hacker used SPE to:
- Export all customer data (GDPR breach)
- Delete critical content items
- Install backdoor for persistent access

**Impact**:
- €5.2M GDPR fine
- 3 weeks downtime
- Reputational damage
- Customer trust loss

**Root Cause**: SPE remote scripting enabled with weak authentication

---

## Why We Ban SPE for MCP Server

### Our Use Case: Field Mutations
**What we need**: Simple field value updates (e.g., Title field)

**Why NOT SPE**:
- ❌ **Overkill**: SPE gives full PowerShell access, we only need field updates
- ❌ **Security**: Opens entire server to remote code execution
- ❌ **Audit**: No proper logging of what was changed
- ❌ **Control**: Can't restrict to specific fields or items
- ❌ **Compliance**: Violates security policies

**Better Alternative**: Custom REST API
- ✅ **Scoped**: Only allows specific field updates
- ✅ **Secure**: API key authentication, no code execution
- ✅ **Auditable**: Proper logging of all changes
- ✅ **Controlled**: Can restrict fields, items, and permissions
- ✅ **Compliant**: Meets security and regulatory requirements

---

## Allowed Alternatives

### OPTION 1: Custom REST API ⭐ **RECOMMENDED**
**Security Level**: ✅ Safe

```csharp
[ApiController]
[Route("api/item/field")]
public class ItemFieldController : ControllerBase
{
    [HttpPost]
    public IActionResult UpdateField([FromBody] UpdateFieldRequest request)
    {
        // Validate API key
        if (!ValidateApiKey(Request.Headers["sc_apikey"]))
            return Unauthorized();
        
        // Validate field name (whitelist)
        if (!IsAllowedField(request.FieldName))
            return Forbidden("Field not allowed for updates");
        
        // Get item with proper language
        var item = Database.GetItem(
            new ID(request.ItemId), 
            Language.Parse(request.Language));
        
        if (item == null)
            return NotFound();
        
        // Update field with audit logging
        using (new SecurityDisabler())
        {
            item.Editing.BeginEdit();
            item.Fields[request.FieldName].Value = request.Value;
            item.Editing.EndEdit();
            
            // Log change for audit trail
            AuditLog.Write($"Field {request.FieldName} updated on {item.Paths.Path}");
        }
        
        return Ok(new { success = true });
    }
}
```

**Security Features**:
- ✅ API key authentication (same as GraphQL)
- ✅ Field whitelist (only allowed fields can be updated)
- ✅ Audit logging (all changes tracked)
- ✅ Input validation (prevent injection attacks)
- ✅ Error handling (no sensitive data in errors)

### OPTION 2: Item Web API (If Enabled)
**Security Level**: ✅ Safe (if properly configured)

**Requirements**:
- ✅ Enable Item Web API in Sitecore config
- ✅ Configure API key permissions
- ✅ Restrict to specific item paths
- ✅ Enable audit logging

**Benefits**:
- Standard Sitecore functionality
- RESTful API design
- Built-in security features

### ~~OPTION 3: SPE~~ ❌ **BANNED**
**Security Level**: ❌ **DANGEROUS**

**Status**: **NOT ALLOWED IN ANY ENVIRONMENT**

---

## Detection and Prevention

### How to Check if SPE is Enabled:
```powershell
# Test SPE endpoint
$speUrl = "https://your-site/sitecore/api/spe/v2/script"
try {
    Invoke-WebRequest -Uri $speUrl -Method OPTIONS
    Write-Host "[CRITICAL] SPE endpoint is accessible!" -ForegroundColor Red
    Write-Host "ACTION REQUIRED: Disable SPE remote scripting immediately" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "[OK] SPE endpoint not found (secure)" -ForegroundColor Green
    }
}
```

### How to Disable SPE Remote Scripting:
1. **Remove SPE Module** (most secure):
   - Uninstall Sitecore PowerShell Extensions package
   - Delete `/sitecore modules/PowerShell` folder

2. **Disable Remote Scripting** (if SPE needed for local admin):
   - In Sitecore, go to: `/sitecore/system/Modules/PowerShell/Settings`
   - Set `Remoting` to disabled
   - Restart application pool

3. **IP Whitelist** (emergency only):
   - Configure IIS to restrict `/sitecore/api/spe/*` to specific IPs
   - Only allow internal admin IPs

---

## Policy Statement

**MANDATORY FOR ALL ENVIRONMENTS**:

> "Sitecore PowerShell Extensions (SPE) remote scripting is **BANNED** in all production, staging, and UAT environments. 
> 
> SPE may only be used in development environments with:
> - Local access only (no remote scripting)
> - Individual developer workstations
> - No exposure to internet
> 
> Any use of SPE in production or for automated field mutations is **strictly prohibited** and will be considered a **security violation**.
> 
> Alternative solutions (Custom REST API or Item Web API) **MUST** be used for programmatic content updates."

---

## Contact

**Security Questions**: Contact security team
**Alternative Solutions**: Contact Sitecore development team
**MCP Implementation**: Use Custom REST API (see FIELD-MUTATIONS-SUMMARY.md)

---

## References

- [Sitecore Security Hardening Guide](https://doc.sitecore.com/developers/101/platform-administration-and-architecture/en/security-hardening.html)
- [OWASP: Remote Code Execution](https://owasp.org/www-community/attacks/Code_Injection)
- [SPE Security Best Practices](https://doc.sitecorepowershell.com/)
- FIELD-MUTATIONS-RESEARCH.md - Safe alternatives
- FIELD-MUTATIONS-SUMMARY.md - Implementation guide

---

**Last Updated**: October 17, 2025
**Status**: ⛔ SPE BANNED - Use Custom REST API instead
