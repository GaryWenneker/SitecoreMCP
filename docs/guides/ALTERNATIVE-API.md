# Alternative Solution: Sitecore Item Web API

Given the complexity of the SPE Remoting API configuration, here is an alternative approach using the standard Sitecore Item Web API (which is always available).

## Advantages:
- ✅ Always available in Sitecore
- ✅ No extra configuration needed
- ✅ RESTful API
- ✅ Supports queries

## Item Web API Endpoints:

### Get Item
```
GET https://your-sitecore-instance.com/sitecore/api/ssc/item/{id}?sc_apikey={apikey}
GET https://your-sitecore-instance.com/sitecore/api/ssc/item/sitecore/content/Home?sc_apikey={apikey}
```

### Get Children
```
GET https://your-sitecore-instance.com/sitecore/api/ssc/item/{id}/children?sc_apikey={apikey}
```

### Query
```
GET https://your-sitecore-instance.com/sitecore/api/ssc/item/query?query=/sitecore/content//*&sc_apikey={apikey}
```

## Configuration:

### 1. Create API Key

In Sitecore:
1. Login as admin
2. Go to: `/sitecore/system/Settings/Services/API Keys`
3. Create new API Key item
4. Set properties:
   - CORS Origins: *
   - Allowed Controllers: *
   - Impersonation User: sitecore\admin

### 2. Test API

```powershell
$apiKey = "your-api-key-here"
Invoke-RestMethod -Uri "https://your-sitecore-instance.com/sitecore/api/ssc/item/sitecore/content?sc_apikey=$apiKey"
```

## Advantages vs SPE:
- Faster (no PowerShell runtime overhead)
- Simpler to configure
- Better for production
- Native JSON responses

Would you like me to update the MCP server to use this API?
