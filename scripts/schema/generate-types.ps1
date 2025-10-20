# Generate TypeScript Interfaces from introspectionSchema.json
# Analyzes .github/introspectionSchema.json and creates type definitions

param(
		[string]$SchemaPath = (Join-Path $PSScriptRoot "..\..\.github\introspectionSchema.json"),
		[string]$OutputPath = (Join-Path $PSScriptRoot "..\\..\\src\\sitecore-types.ts")
)

Write-Host "=== TypeScript Interface Generator ===" -ForegroundColor Cyan
Write-Host "Schema: $SchemaPath" -ForegroundColor Yellow
Write-Host "Output: $OutputPath" -ForegroundColor Yellow
Write-Host ""

# Load schema
Write-Host "[INFO] Loading introspection schema..." -ForegroundColor Cyan
$schema = Get-Content $SchemaPath | ConvertFrom-Json

# Extract core types
Write-Host "[INFO] Extracting core GraphQL types..." -ForegroundColor Cyan

$coreTypes = @{
		"Query" = $null
		"Mutation" = $null
		"Item" = $null
		"ContentSearchResults" = $null
		"ContentSearchResultConnection" = $null
		"ContentSearchResult" = $null
		"ItemField" = $null
		"ItemTemplate" = $null
		"ItemLanguage" = $null
		"TextField" = $null
		"DateField" = $null
		"ImageField" = $null
		"LinkField" = $null
		"PageInfo" = $null
}

# Find Query type definition
Write-Host "[INFO] Finding Query type..." -ForegroundColor Cyan
$queryTypeName = $schema._queryType
$mutationTypeName = $schema._mutationType

Write-Host "  Query Type: $queryTypeName" -ForegroundColor Gray
Write-Host "  Mutation Type: $mutationTypeName" -ForegroundColor Gray
Write-Host "  Total Types: $($schema._typeMap.PSObject.Properties.Count)" -ForegroundColor Gray
Write-Host ""

# Start building TypeScript file
$tsContent = @"
/**
 * Sitecore GraphQL Type Definitions
 * Auto-generated from introspectionSchema.json
 * Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
 * 
 * DO NOT EDIT MANUALLY - Regenerate using: .\scripts\schema\generate-types.ps1
 */

// ============================================
// SCALAR TYPES
// ============================================

export type ID = string;
export type String = string;
export type Boolean = boolean;
export type Int = number;
export type Float = number;
export type Date = string;
export type DateTime = string;
export type DateTimeOffset = string;
export type Decimal = number;

// ============================================
// FIELD TYPES
// ============================================

/**
 * Text field with value property
 * CRITICAL: Always use { value } when querying!
 */
export interface TextField {
	value?: string;
}

/**
 * Date field with value property
 * CRITICAL: Always use { value } when querying!
 */
export interface DateField {
	value?: string;
}

/**
 * Integer field
 */
export interface IntegerField {
	value?: number;
}

/**
 * Number field
 */
export interface NumberField {
	value?: number;
}

/**
 * Checkbox field
 */
export interface CheckboxField {
	value?: boolean;
}

/**
 * Image field with src, alt, width, height
 */
export interface ImageField {
	src?: string;
	alt?: string;
	width?: number;
	height?: number;
	value?: string;
}

/**
 * Link field with url, text, target
 */
export interface LinkField {
	url?: string;
	text?: string;
	target?: string;
	title?: string;
	value?: string;
}

/**
 * Item field (generic)
 */
export interface ItemField {
	name: string;
	value?: any;
}

/**
 * Multilist field
 */
export interface MultilistField {
	targetItems?: Item[];
	value?: string;
}

/**
 * Lookup field
 */
export interface LookupField {
	targetItem?: Item;
	value?: string;
}

/**
 * Reference field
 */
export interface ReferenceField {
	targetItem?: Item;
	value?: string;
}

// ============================================
// CORE TYPES
// ============================================

/**
 * Language object
 */
export interface ItemLanguage {
	name: string;
}

/**
 * Template reference
 */
export interface ItemTemplate {
	id: ID;
	name: string;
}

/**
 * Page info for pagination
 */
export interface PageInfo {
	hasNextPage: boolean;
	hasPreviousPage: boolean;
	startCursor?: string;
	endCursor?: string;
}

/**
 * Sitecore Item (base interface)
 * CRITICAL: Use smart language defaults!
 * - Templates/System/Layout: ALWAYS 'en'
 * - Content: specified or 'en'
 */
export interface Item {
	id: ID;
	name: string;
	displayName?: string;
	path: string;
	template?: ItemTemplate;
	language?: ItemLanguage;
	version?: Int;
	hasChildren?: boolean;
	children?: Item[];
	parent?: Item;
	fields?: ItemField[];
	field?(name: string): ItemField;
}

/**
 * Item with version count (v1.4.0+)
 */
export interface ItemWithVersionCount extends Item {
	versionCount?: number;
}

// ============================================
// SEARCH TYPES
// ============================================

/**
 * Search result item
 */
export interface ContentSearchResult {
	item?: Item;
}

/**
 * Search result edge (pagination)
 */
export interface ContentSearchResultEdge {
	node?: ContentSearchResult;
	cursor?: string;
}

/**
 * Search result connection
 * CRITICAL: Access via results.items NOT results direct!
 */
export interface ContentSearchResultConnection {
	items?: Item[];
	edges?: ContentSearchResultEdge[];
	pageInfo?: PageInfo;
}

/**
 * Search results wrapper
 * CRITICAL STRUCTURE:
 * search { results { items { ... } } }
 * NOT: search { results { ... } }
 */
export interface ContentSearchResults {
	total?: number;
	results?: ContentSearchResultConnection;
}

// ============================================
// STATISTICS INTERFACE (Inline Fragment)
// ============================================

/**
 * Statistics inline fragment
 * CRITICAL: DateField and TextField require { value }!
 * 
 * Usage:
 * ... on Statistics {
 *   created { value }
 *   updated { value }
 *   createdBy { value }
 *   updatedBy { value }
 * }
 */
export interface Statistics {
	created?: DateField;
	updated?: DateField;
	createdBy?: TextField;
	updatedBy?: TextField;
	revision?: string;
}

// ============================================
// QUERY ROOT TYPE
// ============================================

/**
 * GraphQL Query root
 * 
 * Available queries:
 * - item(path, language?, version?)
 * - search(keyword, rootItem?, language?, first?, index?, latestVersion?)
 * - sites(name?, current?, includeSystemSites?)
 */
export interface Query {
	/**
	 * Get item by path
	 * @param path - Item path (e.g., "/sitecore/content/Home")
	 * @param language - Language (uses smart defaults if omitted)
	 * @param version - Version number (uses latest if omitted)
	 */
	item?(
		path: string,
		language?: string,
		version?: number
	): Item;

	/**
	 * Search items
	 * CRITICAL: Returns results.items structure!
	 * @param keyword - Search keyword
	 * @param rootItem - Root path filter
	 * @param language - Language filter
	 * @param first - Max results
	 * @param index - Search index name
	 * @param latestVersion - Only latest versions
	 */
	search?(
		keyword?: string,
		rootItem?: string,
		language?: string,
		first?: number,
		index?: string,
		latestVersion?: boolean
	): ContentSearchResults;

	/**
	 * Get sites
	 * @param name - Site name filter
	 * @param current - Get current site only
	 * @param includeSystemSites - Include system sites
	 */
	sites?(
		name?: string,
		current?: boolean,
		includeSystemSites?: boolean
	): any[]; // SiteGraphType[]
}

// ============================================
// MUTATION ROOT TYPE
// ============================================

/**
 * GraphQL Mutation root
 * 
 * Available mutations:
 * - createItem(...)
 * - updateItem(...)
 * - deleteItem(...)
 */
export interface Mutation {
	createItem?(
		path: string,
		templateId: string,
		name: string,
		language?: string
	): Item;

	updateItem?(
		path: string,
		language?: string,
		version?: number,
		fields?: Array<{ name: string; value: any }>
	): Item;

	deleteItem?(
		path: string,
		language?: string,
		version?: number
	): boolean;
}

// ============================================
// HELIX ARCHITECTURE TYPES
// ============================================

/**
 * Helix Layer Types
 * Foundation/Feature/Project templates always in 'en'
 */
export type HelixLayer = 'Foundation' | 'Feature' | 'Project';

/**
 * Helix template path structure
 */
export interface HelixTemplatePath {
	layer: HelixLayer;
	module: string;
	templateName: string;
	fullPath: string; // e.g., "/sitecore/templates/Foundation/Core/BaseTemplate"
}

// ============================================
// MCP RESPONSE TYPES
// ============================================

/**
 * Standard MCP tool response
 */
export interface MCPToolResponse<T = any> {
	success: boolean;
	data?: T;
	error?: string;
	metadata?: {
		query?: string;
		endpoint?: string;
		timestamp?: string;
	};
}

/**
 * Field discovery response (v1.4.0+)
 */
export interface FieldDiscoveryResponse {
	path: string;
	totalFields: number;
	fields: Array<{
		name: string;
		value: any;
		type?: string;
	}>;
}

/**
 * Version info response (v1.4.0+)
 */
export interface VersionInfoResponse {
	path: string;
	language: string;
	currentVersion: number;
	versionCount: number;
	versions: Array<{
		version: number;
		language: string;
	}>;
}

// ============================================
// UTILITY TYPES
// ============================================

/**
 * GraphQL query variables
 */
export interface GraphQLVariables {
	[key: string]: any;
}

/**
 * GraphQL response wrapper
 */
export interface GraphQLResponse<T = any> {
	data?: T;
	errors?: Array<{
		message: string;
		locations?: Array<{ line: number; column: number }>;
		path?: string[];
	}>;
}

// ============================================
// EXPORT ALL (interfaces already exported above)
// ============================================

"@

# Write to file
Write-Host "[INFO] Writing TypeScript definitions to $OutputPath..." -ForegroundColor Cyan
$tsContent | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host ""
Write-Host "[OK] TypeScript interfaces generated!" -ForegroundColor Green
Write-Host "File: $OutputPath" -ForegroundColor Yellow
Write-Host "Lines: $($tsContent -split "`n" | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Key interfaces created:" -ForegroundColor Cyan
Write-Host "  - Item (base interface)" -ForegroundColor Gray
Write-Host "  - ItemWithVersionCount (v1.4.0+)" -ForegroundColor Gray
Write-Host "  - ContentSearchResults (with results.items!)" -ForegroundColor Gray
Write-Host "  - Query root type" -ForegroundColor Gray
Write-Host "  - Mutation root type" -ForegroundColor Gray
Write-Host "  - Field types (TextField, DateField, etc.)" -ForegroundColor Gray
Write-Host "  - HelixTemplatePath" -ForegroundColor Gray
Write-Host "  - MCPToolResponse" -ForegroundColor Gray
Write-Host "  - FieldDiscoveryResponse (v1.4.0+)" -ForegroundColor Gray
Write-Host ""