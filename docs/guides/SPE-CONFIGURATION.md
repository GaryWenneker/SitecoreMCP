# Sitecore PowerShell Extensions - Remoting Configuration

## Problem: "restfulv2 service is disabled"

If you see the error: "the request could not be completed because the restfulv2 service is disabled", you need to enable the SPE RESTful API service.

## Solution

### Step 1: Find the SPE configuration

Look for the configuration file:
```
App_Config\Include\Spe\Spe.config
```

Or in newer versions:
```
App_Config\Include\Spe\Spe.Services.config
```

### Step 2: Enable restfulv2 service

Find the `<services>` section and ensure `restfulv2` is enabled:

```xml
<spe>
  <services>
    <restfulv2 enabled="true">
      <authorization>
        <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
        <add Permission="Allow" IdentityType="Role" Identity="sitecore\PowerShell Extensions Remoting" />
        <add Permission="Allow" IdentityType="Role" Identity="sitecore\Developer" />
        <add Permission="Allow" IdentityType="Role" Identity="sitecore\IsAdministrator" />
      </authorization>
    </restfulv2>
  </services>
</spe>
```

### Step 3: Check remoting section

Ensure the general remoting section is also enabled:

```xml
<spe>
  <remoting enabled="true" requireSecureConnection="false">
    <authorization>
      <add Permission="Allow" IdentityType="Role" Identity="sitecore\PowerShell Extensions Remoting" />
      <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
      <add Permission="Allow" IdentityType="Role" Identity="sitecore\Developer" />
      <add Permission="Allow" IdentityType="Role" Identity="sitecore\IsAdministrator" />
    </authorization>
  </remoting>
</spe>
```

### Step 4: Complete example configuration

Here is a complete working configuration:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration xmlns:patch="http://www.sitecore.net/xmlconfig/">
  <sitecore>
    <powershell>
      <services>
        <remoting enabled="true" requireSecureConnection="false">
          <authorization>
            <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
            <add Permission="Allow" IdentityType="Role" Identity="sitecore\PowerShell Extensions Remoting" />
            <add Permission="Allow" IdentityType="Role" Identity="sitecore\Developer" />
            <add Permission="Allow" IdentityType="Role" Identity="sitecore\IsAdministrator" />
          </authorization>
        </remoting>
        
        <restfulv2 enabled="true">
          <authorization>
            <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
            <add Permission="Allow" IdentityType="Role" Identity="sitecore\PowerShell Extensions Remoting" />
            <add Permission="Allow" IdentityType="Role" Identity="sitecore\Developer" />
            <add Permission="Allow" IdentityType="Role" Identity="sitecore\IsAdministrator" />
          </authorization>
        </restfulv2>
        
        <fileDownload enabled="true">
          <authorization>
            <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
            <add Permission="Allow" IdentityType="Role" Identity="sitecore\PowerShell Extensions Remoting" />
          </authorization>
        </fileDownload>
        
        <fileUpload enabled="true">
          <authorization>
            <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
            <add Permission="Allow" IdentityType="Role" Identity="sitecore\PowerShell Extensions Remoting" />
          </authorization>
        </fileUpload>
        
        <mediaDownload enabled="true">
          <authorization>
            <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
            <add Permission="Allow" IdentityType="Role" Identity="sitecore\PowerShell Extensions Remoting" />
          </authorization>
        </mediaDownload>
        
        <mediaUpload enabled="true">
          <authorization>
            <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
            <add Permission="Allow" IdentityType="Role" Identity="sitecore\PowerShell Extensions Remoting" />
          </authorization>
        </mediaUpload>
        
        <handleDownload enabled="true">
          <authorization>
            <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
          </authorization>
        </handleDownload>
        
        <client enabled="true">
          <authorization>
            <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
          </authorization>
        </client>
        
        <execution enabled="true">
          <authorization>
            <add Permission="Allow" IdentityType="User" Identity="sitecore\admin" />
          </authorization>
        </execution>
      </services>
    </powershell>
  </sitecore>
</configuration>
```

### Step 5: Restart Sitecore

After modifying the configuration:
1. Save the file
2. IIS Reset: `iisreset` in Administrator PowerShell
3. Or recycle the Application Pool in IIS Manager

### Step 6: Test the API

Run the test script:
```powershell
.\test-spe-api.ps1 -Password "c"
```

## Different SPE Versions

### SPE 6.x and higher
Uses: `/-/script/v2`

### SPE 5.x
Uses: `/sitecore/api/spe/v2/script`

### SPE 4.x and older
Uses: `/-/script`

## Troubleshooting

### "restfulv2 service is disabled"
➡️ Enable `restfulv2` in Spe.Services.config

### HTTP 403 Forbidden
➡️ Check authorization settings for your user/role

### HTTP 404 Not Found
➡️ SPE not installed or wrong endpoint

### "Authentication failed"
➡️ Wrong credentials or user doesn't have SPE rights

## Security Note

⚠️ **Warning**: This configuration is for LOCAL development!

For production:
- ✅ Enable `requireSecureConnection="true"`
- ✅ Restrict authorization to specific users/roles
- ✅ Use strong passwords
- ✅ Disable services you don't use
- ✅ Monitor API logs for abuse
