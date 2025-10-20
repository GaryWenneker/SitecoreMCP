# Relationship Graph Builder
# Recursively follows item references to build complete relationship graph

param(
    [string]$Output = (Join-Path $PSScriptRoot "..\\..\\.schema-analysis\\relationship-graph.json")
)

# Load environment variables from .env file (canonical)
. "$PSScriptRoot\Load-DotEnv.ps1"
Load-DotEnv -EnvFile "$PSScriptRoot\..\..\.env"

# Load field reference parser (from tools folder)
. "$PSScriptRoot\parse-field-references.ps1"

Write-Host "" 
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Relationship Graph Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Global tracking
$script:visitedItems = @{}
$script:relationshipGraph = @{
    Nodes = @()
    Edges = @()
}
$script:circularReferences = @()

function Get-ItemByPath {
    param(
        [string]$Path,
        [string]$Language = "en"
    )
    
    Write-Host "[QUERY] Getting item: $Path" -ForegroundColor Yellow
    
    $headers = @{
        "sc_apikey" = $env:SITECORE_API_KEY
        "Content-Type" = "application/json"
    }
    
    $endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
    
    $query = @{
        query = @"
{
  item(path: "$Path", language: "$Language") {
    id
    name
    displayName
    path
    template {
      id
      name
      path
    }
    language {
      name
    }
  }
}
"@
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $query -Headers $headers
        return $response.data.item
    }
    catch {
        Write-Host "[ERROR] Failed to get item: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-ItemFields {
    param(
        [string]$Path,
        [string]$Language = "en"
    )
    
    Write-Host "[QUERY] Getting fields for: $Path" -ForegroundColor Yellow
    
    $headers = @{
        "sc_apikey" = $env:SITECORE_API_KEY
        "Content-Type" = "application/json"
    }
    
    $endpoint = "$($env:SITECORE_HOST)/sitecore/api/graph/items/master"
    
    $query = @{
        query = @"
{
  item(path: "$Path", language: "$Language") {
    fields(ownFields: false) {
      name
      value
    }
  }
}
"@
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $query -Headers $headers
        if ($response.data.item) {
            return $response.data.item.fields
        }
        return @()
    }
    catch {
        Write-Host "[ERROR] Failed to get fields: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Build-RelationshipGraph {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RootPath,
        [string]$Language = "en",
        [int]$MaxDepth = 3,
        [int]$CurrentDepth = 0
    )
    
    Write-Host ""
    Write-Host "$([string]::new("`t", $CurrentDepth))[DEPTH $CurrentDepth] Processing: $RootPath" -ForegroundColor Cyan
    
    # Check depth limit
    if ($CurrentDepth -ge $MaxDepth) {
        Write-Host "$([string]::new("`t", $CurrentDepth))[LIMIT] Max depth reached" -ForegroundColor Yellow
        return
    }
    
    # Get item details
    $item = Get-ItemByPath -Path $RootPath -Language $Language
    
    if (-not $item) {
        Write-Host "$([string]::new("`t", $CurrentDepth))[SKIP] Item not found or inaccessible" -ForegroundColor Red
        return
    }
    
    $itemId = $item.id
    
    # Check if already visited (circular reference detection)
    if ($script:visitedItems.ContainsKey($itemId)) {
        Write-Host "$([string]::new("`t", $CurrentDepth))[CIRCULAR] Already visited: $($item.name)" -ForegroundColor Magenta
        $script:circularReferences += @{
            From = $RootPath
            To = $item.path
            ItemId = $itemId
        }
        return
    }
    
    # Mark as visited
    $script:visitedItems[$itemId] = $true
    Write-Host "$([string]::new("`t", $CurrentDepth))[OK] Found: $($item.name)" -ForegroundColor Green
    
    # Add to graph nodes
    $script:relationshipGraph.Nodes += @{
        Id = $itemId
        Name = $item.name
        DisplayName = $item.displayName
        Path = $item.path
        Template = $item.template.name
        TemplatePath = $item.template.path
        Language = $item.language.name
        Depth = $CurrentDepth
    }
    
    # Get fields
    $fields = Get-ItemFields -Path $RootPath -Language $Language
    
    if ($fields.Count -eq 0) {
        Write-Host "$([string]::new("`t", $CurrentDepth))[INFO] No fields found" -ForegroundColor Gray
        return
    }
    
    Write-Host "$([string]::new("`t", $CurrentDepth))[INFO] Found $($fields.Count) fields" -ForegroundColor Gray
    
    # Parse field references
    $refs = Parse-FieldReferences -Fields $fields
    
    # Process GUID references
    foreach ($guidRef in $refs.GuidReferences) {
        Write-Host "$([string]::new("`t", $CurrentDepth))[REF] Following GUID from field: $($guidRef.Field)" -ForegroundColor Yellow
        
        # Add edge to graph
        $script:relationshipGraph.Edges += @{
            From = $itemId
            To = $guidRef.Guid
            Field = $guidRef.Field
            Type = "GUID"
        }
        
        # Note: Cannot follow GUID without search/lookup mechanism
        Write-Host "$([string]::new("`t", $CurrentDepth))[TODO] GUID lookup requires search (not implemented in raw GraphQL)" -ForegroundColor Yellow
    }
    
    # Process path references
    foreach ($pathRef in $refs.PathReferences) {
        Write-Host "$([string]::new("`t", $CurrentDepth))[REF] Following path from field: $($pathRef.Field)" -ForegroundColor Yellow
        
        # Recursively process referenced item
        Build-RelationshipGraph -RootPath $pathRef.Path -Language $Language -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
        
        # Add edge to graph
        $script:relationshipGraph.Edges += @{
            From = $itemId
            To = $pathRef.Path
            Field = $pathRef.Field
            Type = "PATH"
        }
    }
}

function Show-RelationshipGraph {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "      Relationship Graph Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Nodes: $($script:relationshipGraph.Nodes.Count)" -ForegroundColor Yellow
    Write-Host "Edges: $($script:relationshipGraph.Edges.Count)" -ForegroundColor Yellow
    Write-Host "Circular References: $($script:circularReferences.Count)" -ForegroundColor Yellow
    Write-Host ""
    
    if ($script:relationshipGraph.Nodes.Count -gt 0) {
        Write-Host "Nodes by Depth:" -ForegroundColor Cyan
        $nodesByDepth = $script:relationshipGraph.Nodes | Group-Object Depth | Sort-Object Name
        foreach ($group in $nodesByDepth) {
            Write-Host "  Depth $($group.Name): $($group.Count) items" -ForegroundColor Gray
            foreach ($node in $group.Group) {
                Write-Host "    - $($node.Name) ($($node.Template))" -ForegroundColor Gray
                Write-Host "      $($node.Path)" -ForegroundColor DarkGray
            }
        }
        Write-Host ""
    }
    
    if ($script:relationshipGraph.Edges.Count -gt 0) {
        Write-Host "Relationships:" -ForegroundColor Cyan
        foreach ($edge in $script:relationshipGraph.Edges) {
            Write-Host "  [$($edge.Type)] $($edge.Field)" -ForegroundColor Yellow
            Write-Host "    From: $($edge.From)" -ForegroundColor Gray
            Write-Host "    To: $($edge.To)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    if ($script:circularReferences.Count -gt 0) {
        Write-Host "Circular References:" -ForegroundColor Magenta
        foreach ($circular in $script:circularReferences) {
            Write-Host "  [LOOP] $($circular.From) -> $($circular.To)" -ForegroundColor Magenta
        }
        Write-Host ""
    }
}

function Export-RelationshipGraph {
    param(
        [string]$OutputPath = (Join-Path $PSScriptRoot "..\\..\\graph.json")
    )
    
    $export = @{
        Nodes = $script:relationshipGraph.Nodes
        Edges = $script:relationshipGraph.Edges
        CircularReferences = $script:circularReferences
        GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    $export | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    
    Write-Host "[EXPORT] Graph saved to: $OutputPath" -ForegroundColor Green
}

Write-Host "[INFO] This script builds a relationship graph by following references" -ForegroundColor Yellow
Write-Host ""
Write-Host "Usage Example:" -ForegroundColor Cyan
Write-Host "  Build-RelationshipGraph -RootPath '/sitecore/content/Home' -Language 'en' -MaxDepth 3" -ForegroundColor Gray
Write-Host "  Show-RelationshipGraph" -ForegroundColor Gray
Write-Host "  Export-RelationshipGraph -OutputPath (Join-Path $PSScriptRoot '..\\..\\graph.json')" -ForegroundColor Gray
Write-Host ""
Write-Host "[NOTE] This is a DEMONSTRATION script" -ForegroundColor Yellow
Write-Host "[NOTE] For production use, integrate with MCP tools" -ForegroundColor Yellow
Write-Host "[NOTE] GUID resolution requires search functionality" -ForegroundColor Yellow
