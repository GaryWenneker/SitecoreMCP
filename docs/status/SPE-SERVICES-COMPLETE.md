# SPE Configuratie - Alle Services

Je hebt meerdere SPE services die APART ingeschakeld moeten worden!

## Volledige configuratie die nodig is:

```xml
<spe>
  <services>
    <!-- Voor inline PowerShell scripts (dit is wat de MCP server nodig heeft!) -->
    <remoting enabled="true" requireSecureConnection="false">
      <authorization>
        <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
        <add Permission="Allow" IdentityType="Role" Identity="sitecore\PowerShell Extensions Remoting" />
      </authorization>
    </remoting>
    
    <!-- Voor opgeslagen Sitecore scripts -->
    <restfulv2 enabled="true" requireSecureConnection="false">
      <authorization>
        <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
        <add Permission="Allow" IdentityType="Role" Identity="sitecore\PowerShell Extensions Remoting" />
      </authorization>
    </restfulv2>
    
    <!-- Execution service (BELANGRIJK!) -->
    <execution enabled="true">
      <authorization>
        <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
      </authorization>
    </execution>
    
    <!-- File upload/download (optioneel) -->
    <fileDownload enabled="true">
      <authorization>
        <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
      </authorization>
    </fileDownload>
    
    <fileUpload enabled="true">
      <authorization>
        <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
      </authorization>
    </fileUpload>
  </services>
</spe>
```

## IIS Reset na wijziging!

```powershell
iisreset
```

## Test daarna:

```powershell
.\test-spe-api.ps1 -Password "c"
```
