/**
 * Sitecore GraphQL Type Definitions
 * Auto-generated from introspectionSchema.json
 * Generated: 2025-10-16 19:24:46
 *
 * DO NOT EDIT MANUALLY - Regenerate using: .\generate-types.ps1
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
 * SCHEMA: Query.templates returns [ItemTemplate]
 * Fields from introspectionSchema-FULL.json:
 * - baseTemplates: [ItemTemplate]
 * - fields: [ItemTemplateField]
 * - id: ID! (NON_NULL)
 * - name: String! (NON_NULL)
 * - ownFields: [ItemTemplateField]
 * NOTE: ItemTemplate does NOT have 'path' field!
 */
export interface ItemTemplate {
  id: ID;
  name: string;
  baseTemplates?: ItemTemplate[];
  fields?: ItemTemplateField[];
  ownFields?: ItemTemplateField[];
}

/**
 * Template field definition
 */
export interface ItemTemplateField {
  name: string;
  type?: string;
  title?: string;
  section?: string;
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
  item?(path: string, language?: string, version?: number): Item;

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
  sites?(name?: string, current?: boolean, includeSystemSites?: boolean): any[]; // SiteGraphType[]
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
  createItem?(path: string, templateId: string, name: string, language?: string): Item;

  updateItem?(
    path: string,
    language?: string,
    version?: number,
    fields?: Array<{ name: string; value: any }>
  ): Item;

  deleteItem?(path: string, language?: string, version?: number): boolean;
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
