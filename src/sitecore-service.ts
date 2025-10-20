import axios, { AxiosInstance } from 'axios';
import https from 'https';

export interface SitecoreItem {
  id: string;
  name: string;
  displayName: string;
  path: string;
  templateId: string;
  templateName: string;
  language: string;
  version: number;
  fields: Record<string, any>;
  hasChildren: boolean;
  parentId?: string;
  created?: string;
  updated?: string;
}

interface GraphQLResponse {
  data?: any;
  errors?: Array<{ message: string }>;
}

export class SitecoreService {
  private client: AxiosInstance;
  private graphqlEndpoint: string;
  private apiKey: string;

  constructor(
    private sitecoreHost: string,
    private username: string,
    private password: string,
    apiKey?: string,
    endpoint?: string
  ) {
    // GraphQL API endpoint - configurable via parameter or environment variable
    // Default: /sitecore/api/graph/items/master
    // Alternative: /sitecore/api/graph/items/web (for published content)
    this.graphqlEndpoint =
      endpoint ||
      process.env.SITECORE_ENDPOINT ||
      `${this.sitecoreHost}/sitecore/api/graph/items/master`;
    this.apiKey = apiKey || process.env.SITECORE_API_KEY || '';

    // Validate API key is present
    if (!this.apiKey) {
      throw new Error('SITECORE_API_KEY is required but not provided');
    }

    // Create axios instance with authentication
    this.client = axios.create({
      httpsAgent: new https.Agent({
        rejectUnauthorized: false, // For local development with self-signed certs
      }),
      timeout: 30000,
      headers: {
        // These headers are REQUIRED for every GraphQL request
        sc_apikey: this.apiKey,
        'Content-Type': 'application/json',
      },
    });

    // Add Basic Auth as fallback (optional)
    if (username && password) {
      const auth = Buffer.from(`${username}:${password}`).toString('base64');
      this.client.defaults.headers.common['Authorization'] = `Basic ${auth}`;
    }
  }

  /**
   * Execute GraphQL query tegen Sitecore
   */
  private async executeGraphQL(query: string, variables?: any): Promise<any> {
    try {
      const response = await this.client.post<GraphQLResponse>(this.graphqlEndpoint, {
        query,
        variables,
      });

      if (response.data.errors) {
        throw new Error(`GraphQL Error: ${response.data.errors.map((e) => e.message).join(', ')}`);
      }

      return response.data.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        if (error.response?.data?.errors) {
          throw new Error(
            `GraphQL Error: ${error.response.data.errors.map((e: any) => e.message).join(', ')}`
          );
        }
        throw new Error(`GraphQL API Error: ${error.message}`);
      }
      throw error;
    }
  }

  /**
   * Format GUID to Sitecore format with curly braces and dashes
   * CRITICAL: Sitecore GraphQL returns GUIDs WITHOUT dashes (CFFDFAFA317F4E5498988D16E6BB1E68)
   * but queries REQUIRE dashes ({CFFDFAFA-317F-4E54-9898-8D16E6BB1E68})
   *
   * @param guid - GUID string with or without dashes/curly braces
   * @returns Formatted GUID: {XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
   */
  private formatGuid(guid: string): string {
    // Remove curly braces if present
    const cleanGuid = guid.replace(/[{}]/g, '');

    // If already has dashes, just add curly braces
    if (cleanGuid.includes('-')) {
      return `{${cleanGuid}}`;
    }

    // Add dashes in 8-4-4-4-12 format
    if (cleanGuid.length === 32) {
      return `{${cleanGuid.substring(0, 8)}-${cleanGuid.substring(8, 12)}-${cleanGuid.substring(12, 16)}-${cleanGuid.substring(16, 20)}-${cleanGuid.substring(20, 32)}}`;
    }

    // If format is unexpected, return as-is with curly braces
    return `{${cleanGuid}}`;
  }

  /**
   * Get available languages for an item
   * Tries common languages and returns which ones have content
   * @param path - Item path or GUID
   * @returns Array of available language codes
   */
  private async getAvailableLanguages(path: string): Promise<string[]> {
    const commonLanguages = ['en', 'nl', 'nl-NL', 'de-DE', 'fr-FR', 'es-ES', 'da', 'de', 'fr', 'es'];
    const availableLanguages: string[] = [];

    // Try each language with a simple query
    for (const lang of commonLanguages) {
      try {
        const query = `
          query CheckLanguage($path: String!, $language: String!) {
            item(path: $path, language: $language) {
              id
            }
          }
        `;
        const result = await this.executeGraphQL(query, { path, language: lang });
        if (result.item) {
          availableLanguages.push(lang);
        }
      } catch {
        // Language not available, continue
      }
    }

    return availableLanguages;
  }

  /**
   * Determine smart language default based on path
   * SITECORE BEST PRACTICE:
   * - Templates, renderings, system items: ALWAYS 'en'
   * - Content items: Use specified language or 'en' as fallback
   *
   * HELIX ARCHITECTURE:
   * - Foundation layer: /sitecore/templates/Foundation
   * - Feature layer: /sitecore/templates/Feature
   * - Project layer: /sitecore/templates/Project
   * - All templates MUST be in 'en' language
   */
  private getSmartLanguageDefault(path: string, specifiedLanguage?: string): string {
    // If language is explicitly specified, use it
    if (specifiedLanguage) {
      return specifiedLanguage;
    }

    // ALWAYS 'en' for:
    // - Templates (Helix: Foundation/Feature/Project)
    // - System items
    // - Layout/Renderings
    // - Media Library (optional, often 'en')
    const systemPaths = [
      '/sitecore/templates',
      '/sitecore/layout',
      '/sitecore/system',
      '/sitecore/media library',
    ];

    const isSystemPath = systemPaths.some((sp) => path.toLowerCase().startsWith(sp.toLowerCase()));

    if (isSystemPath) {
      return 'en'; // REQUIRED: Templates/Renderings are ALWAYS in 'en'
    }

    // For content items under /sitecore/content
    // Default to 'en' but allow override
    return 'en';
  }

  /**
   * Get a single Sitecore item by path or ID
   * SMART DEFAULTS:
   * - Language: Auto-detect ('en' for templates/system, specified or 'en' for content)
   * - Version: Latest version unless specified
   * - Response includes: Total version count
   */
  async getItem(
    path: string,
    language?: string,
    _database: string = 'master',
    version?: number
  ): Promise<SitecoreItem & { versionCount?: number }> {
    // Detect GUID input and format if needed
    let effectivePath = path;
    const guidRegex = /^\{?[A-Fa-f0-9]{8}(-?[A-Fa-f0-9]{4}){3}-?[A-Fa-f0-9]{12}\}?$/;
    if (guidRegex.test(path)) {
      effectivePath = this.formatGuid(path);
      console.error(`[getItem] GUID detected: ${path} → formatted as: ${effectivePath}`);
    }

    // Apply smart language default
    const effectiveLanguage = this.getSmartLanguageDefault(effectivePath, language);

    const query = `
      query GetItem($path: String!, $language: String!, $version: Int) {
        item(path: $path, language: $language, version: $version) {
          id
          name
          displayName
          path
          template {
            id
            name
          }
          hasChildren
          language {
            name
          }
          version
        }
      }
    `;

    const result = await this.executeGraphQL(query, {
      path: effectivePath,
      language: effectiveLanguage,
      version,
    });

    if (!result.item) {
      // Try to get available languages for this item
      let errorMessage = `Item not found: ${path} (formatted as: ${effectivePath}, language: ${effectiveLanguage}${version ? `, version: ${version}` : ''}).`;
      
      try {
        const availableLanguages = await this.getAvailableLanguages(effectivePath);
        if (availableLanguages.length > 0) {
          errorMessage += ` Item exists in: ${availableLanguages.join(', ')}. Try one of these languages.`;
        } else {
          errorMessage += ` Item does not exist in any common language, or path is invalid.`;
        }
      } catch {
        // If language check fails, provide generic hint
        errorMessage += ` The item might exist in a different language. Common languages: en, nl, nl-NL, de, fr.`;
      }
      
      errorMessage += ` Tip: Use sitecore_get_children on the parent folder to see available items.`;
      throw new Error(errorMessage);
    }

    const item = result.item;

    // Get total version count for this language
    let versionCount: number | undefined;
    try {
      const versions = await this.getItemVersions(effectivePath, effectiveLanguage);
      versionCount = versions.length;
    } catch {
      // If version count fails, don't block the response
      versionCount = undefined;
    }

    return {
      id: item.id,
      name: item.name,
      displayName: item.displayName,
      path: item.path,
      templateId: item.template.id,
      templateName: item.template.name,
      language: item.language?.name || effectiveLanguage,
      version: item.version || version || 1,
      hasChildren: item.hasChildren,
      fields: {}, // Fields moeten apart opgevraagd worden met getFieldValue
      versionCount: versionCount,
    };
  }

  /**
   * Get children of a Sitecore item
   * NEW: Supports version parameter
   */
  async getChildren(
  path: string,
    language: string = 'en',
    _database: string = 'master',
    _recursive: boolean = false,
    version?: number
  ): Promise<SitecoreItem[]> {

    // Detect GUID input and format if needed
    let effectivePath = path;
    // GUID: 32 hex chars or {GUID} or GUID with dashes
    const guidRegex = /^\{?[A-Fa-f0-9]{8}(-?[A-Fa-f0-9]{4}){3}-?[A-Fa-f0-9]{12}\}?$/;
    if (guidRegex.test(path)) {
      effectivePath = this.formatGuid(path);
      console.error(`[getChildren] GUID detected: ${path} → formatted as: ${effectivePath}`);
    } else {
      console.error(`[getChildren] Using path as-is: ${path}`);
    }

    const query = `
      query GetChildren($path: String!, $language: String!, $version: Int) {
        item(path: $path, language: $language, version: $version) {
          children(first: 100) {
            id
            name
            displayName
            path
            template {
              id
              name
            }
            hasChildren
          }
        }
      }
    `;

    const result = await this.executeGraphQL(query, { path: effectivePath, language, version });

    if (!result.item) {
      // Try to get available languages for this item
      let errorMessage = `Item not found: ${path} (formatted as: ${effectivePath}, language: ${language}${version ? `, version: ${version}` : ''}).`;
      
      try {
        const availableLanguages = await this.getAvailableLanguages(effectivePath);
        if (availableLanguages.length > 0) {
          errorMessage += ` Item exists in: ${availableLanguages.join(', ')}. Try one of these languages.`;
        } else {
          errorMessage += ` Item does not exist in any common language, or path/GUID is invalid.`;
        }
      } catch {
        // If language check fails, provide generic hint
        errorMessage += ` The item might exist in a different language. Common languages: en, nl, nl-NL, de, fr.`;
      }
      
      errorMessage += ` Tip: Check the GUID format or use sitecore_search to find the item.`;
      throw new Error(errorMessage);
    }

    // In /items/master schema is children een directe array van items
    const children = result.item.children || [];
    return children.map((child: any) => {
      return {
        id: child.id,
        name: child.name,
        displayName: child.displayName,
        path: child.path,
        templateId: child.template.id,
        templateName: child.template.name,
        language: language,
        version: 1,
        hasChildren: child.hasChildren,
        fields: {}, // Fields moeten apart opgevraagd worden per field
      };
    });
  }

  /**
   * Execute a Sitecore query (via GraphQL search)
   */
  async executeQuery(
    queryPath: string,
    language: string = 'en',
    _database: string = 'master',
    maxItems: number = 100
  ): Promise<SitecoreItem[]> {
    const query = `
      query Search($path: String!, $language: String!, $first: Int!) {
        search(
          where: {
            name: "_path"
            value: $path
            operator: CONTAINS
          }
          first: $first
          language: $language
        ) {
          results {
            items {
              id
              name
              displayName
              path
              template {
                id
                name
              }
              hasChildren
              fields {
                name
                value
              }
            }
          }
        }
      }
    `;

    const result = await this.executeGraphQL(query, {
      path: queryPath,
      language,
      first: maxItems,
    });

    const items = result.search?.results?.items || [];
    return items.map((item: any) => {
      const fields: Record<string, any> = {};
      item.fields?.forEach((field: any) => {
        fields[field.name] = field.value;
      });

      return {
        id: item.id,
        name: item.name,
        displayName: item.displayName,
        path: item.path,
        templateId: item.template.id,
        templateName: item.template.name,
        language: language,
        version: 1,
        hasChildren: item.hasChildren,
        fields,
      };
    });
  }

  /**
   * Search for items by name (BACKWARDS COMPATIBLE - returns just array)
   * NEW for /items/master: Enhanced with facets, field filtering, index selection
   * ENHANCED: Client-side filters (path_contains, name_contains, template_in, hasChildren, hasLayout)
   * ENHANCED: Client-side sorting (orderBy: name, displayName, path)
   * For pagination support, use searchItemsPaginated() instead
   */
  async searchItems(
    searchText?: string,
    rootPath?: string,
    templateName?: string,
    language: string = 'en',
    _database: string = 'master',
    maxItems: number = 50,
    index?: string,
    fieldsEqual?: Array<{ field: string; value: string }>,
    facetOn?: string[],
    latestVersion?: boolean,
    filters?: {
      pathContains?: string;
      pathStartsWith?: string;
      nameContains?: string;
      templateIn?: string[];
      hasChildrenFilter?: boolean;
      hasLayoutFilter?: boolean;
    },
    orderBy?: Array<{ field: 'name' | 'displayName' | 'path'; direction: 'ASC' | 'DESC' }>
  ): Promise<SitecoreItem[]> {
    // NOTE: ContentSearchResult has DIFFERENT fields than Item!
    // ContentSearchResult fields: id, name, path, templateName, uri, language (String!)
    // Item fields: id, name, displayName, path, template, hasChildren, fields
    const query = `
      query Search(
        $keyword: String
        $rootItem: String
        $language: String
        $first: Int
        $index: String
        $latestVersion: Boolean
      ) {
        search(
          keyword: $keyword
          rootItem: $rootItem
          language: $language
          first: $first
          index: $index
          latestVersion: $latestVersion
        ) {
          results {
            items {
              id
              name
              path
              templateName
              uri
              language
            }
          }
        }
      }
    `;

    const result = await this.executeGraphQL(query, {
      keyword: searchText,
      rootItem: rootPath,
      language,
      first: maxItems,
      index,
      latestVersion,
    });

    let items = result.search?.results?.items || [];

    // Filter op templateName indien nodig
    if (templateName) {
      items = items.filter((item: any) => item.templateName === templateName);
    }

    // Apply enhanced client-side filters
    if (filters) {
      if (filters.pathContains) {
        items = items.filter((item: any) =>
          item.path.toLowerCase().includes(filters.pathContains!.toLowerCase())
        );
      }
      if (filters.pathStartsWith) {
        items = items.filter((item: any) =>
          item.path.toLowerCase().startsWith(filters.pathStartsWith!.toLowerCase())
        );
      }
      if (filters.nameContains) {
        items = items.filter((item: any) =>
          item.name.toLowerCase().includes(filters.nameContains!.toLowerCase())
        );
      }
      if (filters.templateIn && filters.templateIn.length > 0) {
        items = items.filter((item: any) => filters.templateIn!.includes(item.templateName));
      }
      if (filters.hasChildrenFilter !== undefined) {
        // Note: ContentSearchResult does NOT have hasChildren field
        // This filter will be ignored for search results
        console.warn('hasChildrenFilter is not supported by ContentSearchResult, filter ignored');
      }
      if (filters.hasLayoutFilter !== undefined) {
        // Note: ContentSearchResult does NOT have fields array
        // This filter will be ignored for search results
        console.warn('hasLayoutFilter is not supported by ContentSearchResult, filter ignored');
      }
    }

    // Apply client-side sorting
    if (orderBy && orderBy.length > 0) {
      items.sort((a: any, b: any) => {
        for (const sort of orderBy) {
          const aVal = a[sort.field] || '';
          const bVal = b[sort.field] || '';
          const comparison = aVal.localeCompare(bVal, undefined, { sensitivity: 'base' });

          if (comparison !== 0) {
            return sort.direction === 'ASC' ? comparison : -comparison;
          }
        }
        return 0;
      });
    }

    return items.map((item: any) => {
      // ContentSearchResult fields: id, name, path, templateName, uri, language (String)
      // Map to SitecoreItem interface
      return {
        id: item.id,
        name: item.name,
        displayName: item.name, // ContentSearchResult doesn't have displayName, use name
        path: item.path,
        templateId: '', // ContentSearchResult doesn't provide templateId
        templateName: item.templateName,
        language: item.language || language, // language is String, not object!
        version: 1, // ContentSearchResult doesn't provide version
        hasChildren: false, // ContentSearchResult doesn't have hasChildren
        fields: {}, // ContentSearchResult doesn't have fields array
      };
    });
  }

  /**
   * Search for items WITH PAGINATION SUPPORT
   * ENHANCED: Client-side filters (path_contains, name_contains, template_in, hasChildren, hasLayout)
   * ENHANCED: Client-side sorting (orderBy: name, displayName, path)
   * Returns items plus pagination metadata (pageInfo, totalCount)
   */
  async searchItemsPaginated(
    searchText?: string,
    rootPath?: string,
    templateName?: string,
    language: string = 'en',
    _database: string = 'master',
    maxItems: number = 50,
    index?: string,
    fieldsEqual?: Array<{ field: string; value: string }>,
    facetOn?: string[],
    latestVersion?: boolean,
    after?: string,
    filters?: {
      pathContains?: string;
      pathStartsWith?: string;
      nameContains?: string;
      templateIn?: string[];
      hasChildrenFilter?: boolean;
      hasLayoutFilter?: boolean;
    },
    orderBy?: Array<{ field: 'name' | 'displayName' | 'path'; direction: 'ASC' | 'DESC' }>
  ): Promise<{
    items: SitecoreItem[];
    pageInfo: {
      hasNextPage: boolean;
      hasPreviousPage: boolean;
      startCursor: string | null;
      endCursor: string | null;
    };
    totalCount: number | null;
  }> {
    // NOTE: ContentSearchResult has DIFFERENT fields than Item!
    // ContentSearchResult fields: id, name, path, templateName, uri, language (String!)
    const query = `
      query Search(
        $keyword: String
        $rootItem: String
        $language: String
        $first: Int
        $after: String
        $index: String
        $latestVersion: Boolean
      ) {
        search(
          keyword: $keyword
          rootItem: $rootItem
          language: $language
          first: $first
          after: $after
          index: $index
          latestVersion: $latestVersion
        ) {
          results {
            items {
              id
              name
              path
              templateName
              uri
              language
            }
            pageInfo {
              hasNextPage
              hasPreviousPage
              startCursor
              endCursor
            }
            totalCount
          }
        }
      }
    `;

    const result = await this.executeGraphQL(query, {
      keyword: searchText,
      rootItem: rootPath,
      language,
      first: maxItems,
      after,
      index,
      latestVersion,
    });

    let items = result.search?.results?.items || [];
    const pageInfo = result.search?.results?.pageInfo || {
      hasNextPage: false,
      hasPreviousPage: false,
      startCursor: null,
      endCursor: null,
    };
    const totalCount = result.search?.results?.totalCount || null;

    // Filter op templateName indien nodig
    if (templateName) {
      items = items.filter((item: any) => item.templateName === templateName);
    }

    // Apply enhanced client-side filters
    if (filters) {
      if (filters.pathContains) {
        items = items.filter((item: any) =>
          item.path.toLowerCase().includes(filters.pathContains!.toLowerCase())
        );
      }
      if (filters.pathStartsWith) {
        items = items.filter((item: any) =>
          item.path.toLowerCase().startsWith(filters.pathStartsWith!.toLowerCase())
        );
      }
      if (filters.nameContains) {
        items = items.filter((item: any) =>
          item.name.toLowerCase().includes(filters.nameContains!.toLowerCase())
        );
      }
      if (filters.templateIn && filters.templateIn.length > 0) {
        items = items.filter((item: any) => filters.templateIn!.includes(item.templateName));
      }
      if (filters.hasChildrenFilter !== undefined) {
        // Note: ContentSearchResult does NOT have hasChildren field
        console.warn('hasChildrenFilter is not supported by ContentSearchResult, filter ignored');
      }
      if (filters.hasLayoutFilter !== undefined) {
        // Note: ContentSearchResult does NOT have fields array
        console.warn('hasLayoutFilter is not supported by ContentSearchResult, filter ignored');
      }
    }

    // Apply client-side sorting
    if (orderBy && orderBy.length > 0) {
      items.sort((a: any, b: any) => {
        for (const sort of orderBy) {
          const aVal = a[sort.field] || '';
          const bVal = b[sort.field] || '';
          const comparison = aVal.localeCompare(bVal, undefined, { sensitivity: 'base' });

          if (comparison !== 0) {
            return sort.direction === 'ASC' ? comparison : -comparison;
          }
        }
        return 0;
      });
    }

    const mappedItems = items.map((item: any) => {
      // ContentSearchResult fields: id, name, path, templateName, uri, language (String)
      // Map to SitecoreItem interface
      return {
        id: item.id,
        name: item.name,
        displayName: item.name, // ContentSearchResult doesn't have displayName
        path: item.path,
        templateId: '', // ContentSearchResult doesn't provide templateId
        templateName: item.templateName,
        language: item.language || language, // language is String, not object!
        version: 1, // ContentSearchResult doesn't provide version
        hasChildren: false, // ContentSearchResult doesn't have hasChildren
        fields: {}, // ContentSearchResult doesn't have fields array
      };
    });

    return {
      items: mappedItems,
      pageInfo,
      totalCount,
    };
  }

  /**
   * Get a specific field value from an item
   * NEW: Supports version parameter
   */
  async getFieldValue(
    path: string,
    fieldName: string,
    language: string = 'en',
    _database: string = 'master',
    version?: number
  ): Promise<{ fieldName: string; value: any; type: string }> {
    const query = `
      query GetField($path: String!, $fieldName: String!, $language: String!, $version: Int) {
        item(path: $path, language: $language, version: $version) {
          field(name: $fieldName) {
            name
            value
          }
        }
      }
    `;

    const result = await this.executeGraphQL(query, { path, fieldName, language, version });

    if (!result.item || !result.item.field) {
      throw new Error(`Field '${fieldName}' not found in item: ${path}`);
    }

    return {
      fieldName: result.item.field.name,
      value: result.item.field.value,
      type: 'text', // GraphQL geeft geen type terug, default naar text
    };
  }

  /**
   * Get template information
   */
  async getTemplate(templatePath: string, _database: string = 'master'): Promise<any> {
    // Apply smart language default (templates always 'en')
    const language = 'en';

    const query = `
      query GetTemplate($path: String!, $language: String!) {
        item(path: $path, language: $language) {
          id
          name
          path
          template {
            id
            name
          }
          fields(ownFields: false) {
            name
            value
          }
        }
      }
    `;

    const result = await this.executeGraphQL(query, { path: templatePath, language });

    if (!result.item) {
      throw new Error(
        `Template not found: ${templatePath} (language: ${language}). Template items must always be queried with language='en'.`
      );
    }

    return {
      id: result.item.id,
      name: result.item.name,
      path: result.item.path,
      fields: result.item.fields || [],
      baseTemplates: [], // GraphQL basic query geeft geen base templates terug
    };
  }

  /**
   * Get all fields with values for an item based on its template
   * NEW FEATURE: Template-based field discovery
   *
   * When asked for "fields of item X":
   * 1. Get the item to find its template
   * 2. Query all fields from template definition
   * 3. Get actual values for those fields
   * 4. Return complete field list with values
   *
   * HELIX AWARENESS:
   * - Supports inherited fields from base templates
   * - Handles Foundation/Feature/Project template layers
   */
  async getItemFieldsFromTemplate(
    path: string,
    language?: string,
    version?: number
  ): Promise<Array<{ name: string; value: any; type?: string }>> {
    // Apply smart language default
    const effectiveLanguage = this.getSmartLanguageDefault(path, language);

    // Query to get item with ALL its fields
    const query = `
      query GetItemFields($path: String!, $language: String!, $version: Int) {
        item(path: $path, language: $language, version: $version) {
          id
          name
          path
          template {
            id
            name
          }
          fields(ownFields: false) {
            name
            value
          }
        }
      }
    `;

    const result = await this.executeGraphQL(query, {
      path,
      language: effectiveLanguage,
      version,
    });

    if (!result.item) {
      throw new Error(`Item not found: ${path}`);
    }

    // Return all fields with their values
    // ownFields: false includes inherited fields (Helix base templates)
    return (result.item.fields || []).map((field: any) => ({
      name: field.name,
      value: field.value,
      type: 'text', // GraphQL doesn't return field type, could be enhanced
    }));
  }

  /**
   * Get layout/presentation information for an item
   * Schema requires: site (string), routePath (string), language (string)
   */
  async getLayout(site: string, routePath: string, language: string = 'en'): Promise<any> {
    const query = `
      query GetLayout($site: String!, $routePath: String!, $language: String!) {
        layout(site: $site, routePath: $routePath, language: $language) {
          item {
            id
            name
            path
            displayName
          }
          placeholders {
            name
            path
          }
        }
      }
    `;

    const variables = { site, routePath, language };

    const result = await this.executeGraphQL(query, variables);

    if (!result.layout) {
      throw new Error(`Layout not found for site: ${site}, route: ${routePath}`);
    }

    return result.layout;
  }

  /**
   * Get site configuration information
   * NEW for /items/master: Uses plural 'sites' query with filtering
   */
  async getSites(name?: string, current?: boolean, includeSystemSites?: boolean): Promise<any[]> {
    const query = `
      query GetSites($name: String, $current: Boolean, $includeSystemSites: Boolean) {
        sites(name: $name, current: $current, includeSystemSites: $includeSystemSites) {
          name
          hostName
          rootPath
          startItem
          language
          database
        }
      }
    `;

    const result = await this.executeGraphQL(query, { name, current, includeSystemSites });

    if (!result.sites) {
      throw new Error(`Sites information not available`);
    }

    return result.sites;
  }

  /**
   * Get templates information
   * SCHEMA-VALIDATED: Query.templates exists and returns [ItemTemplate]
   * ItemTemplate fields: id, name, baseTemplates, fields, ownFields (NO path!)
   */
  async getTemplates(_path?: string): Promise<any[]> {
    // The templates() query EXISTS in GraphQL schema (Query.templates: [ItemTemplate])
    // But ItemTemplate only has: id, name, baseTemplates, fields, ownFields (NO path!)
    const query = `
      query GetTemplates {
        templates {
          id
          name
          baseTemplates {
            id
            name
          }
          fields {
            name
            type
          }
        }
      }
    `;

    const result = await this.executeGraphQL(query, {});

    if (!result.templates) {
      throw new Error(
        `Templates query failed. Note: ItemTemplate type only has id, name, baseTemplates, fields, ownFields (no path field).`
      );
    }

    // Return templates
    // Note: ItemTemplate does NOT have 'path' field per schema!
    return result.templates;
  }

  /**
   * Create a new Sitecore item
   * NEW for /items/master: Mutation support!
   */
  async createItem(
    name: string,
    template: string,
    parent: string,
    language: string = 'en',
    _fields?: Record<string, any>
  ): Promise<any> {
    const mutation = `
      mutation CreateItem(
        $name: String!
        $template: String!
        $parent: String!
        $language: String
      ) {
        createItem(
          name: $name
          template: $template
          parent: $parent
          language: $language
        ) {
          id
          name
          path
          displayName
        }
      }
    `;

    const result = await this.executeGraphQL(mutation, {
      name,
      template,
      parent,
      language,
    });

    if (!result.createItem) {
      throw new Error(`Failed to create item: ${name}`);
    }

    return result.createItem;
  }

  /**
   * Update an existing Sitecore item
   * NEW for /items/master: Mutation support!
   */
  async updateItem(
    path: string,
    language: string = 'en',
    version?: number,
    name?: string,
    _fields?: Record<string, any>
  ): Promise<any> {
    const mutation = `
      mutation UpdateItem(
        $path: String!
        $language: String
        $version: Int
        $name: String
      ) {
        updateItem(
          path: $path
          language: $language
          version: $version
          name: $name
        ) {
          id
          name
          path
          displayName
        }
      }
    `;

    const result = await this.executeGraphQL(mutation, {
      path,
      language,
      version,
      name,
    });

    if (!result.updateItem) {
      throw new Error(`Failed to update item: ${path}`);
    }

    return result.updateItem;
  }

  /**
   * Delete a Sitecore item
   * NEW for /items/master: Mutation support!
   */
  async deleteItem(path: string, deletePermanently: boolean = false): Promise<boolean> {
    const mutation = `
      mutation DeleteItem($path: String!, $deletePermanently: Boolean) {
        deleteItem(path: $path, deletePermanently: $deletePermanently)
      }
    `;

    const result = await this.executeGraphQL(mutation, {
      path,
      deletePermanently,
    });

    return result.deleteItem === true;
  }

  /**
   * Scan GraphQL schema via introspection
   */
  async scanSchema(): Promise<any> {
    const introspectionQuery = `
      query IntrospectionQuery {
        __schema {
          queryType { name }
          mutationType { name }
          subscriptionType { name }
          types {
            kind
            name
            description
            fields(includeDeprecated: true) {
              name
              description
              args {
                name
                description
                type {
                  kind
                  name
                  ofType {
                    kind
                    name
                    ofType {
                      kind
                      name
                    }
                  }
                }
              }
              type {
                kind
                name
                ofType {
                  kind
                  name
                  ofType {
                    kind
                    name
                  }
                }
              }
            }
            inputFields {
              name
              description
              type {
                kind
                name
                ofType {
                  kind
                  name
                }
              }
            }
            interfaces {
              name
            }
            enumValues(includeDeprecated: true) {
              name
              description
            }
            possibleTypes {
              name
            }
          }
        }
      }
    `;

    const result = await this.executeGraphQL(introspectionQuery, {});
    return result.__schema;
  }

  /**
   * Analyze schema and extract useful information
   */
  async analyzeSchema(): Promise<any> {
    const schema = await this.scanSchema();

    const analysis: any = {
      timestamp: new Date().toISOString(),
      endpoint: this.graphqlEndpoint,
      queryType: schema.queryType?.name || null,
      mutationType: schema.mutationType?.name || null,
      subscriptionType: schema.subscriptionType?.name || null,
      operations: {
        queries: [],
        mutations: [],
        subscriptions: [],
      },
      customTypes: [],
      templateTypes: [],
      inputTypes: [],
    };

    // Process all types
    for (const type of schema.types) {
      // Skip introspection types
      if (type.name.startsWith('__')) continue;

      // Query operations
      if (type.name === schema.queryType?.name && type.fields) {
        for (const field of type.fields) {
          analysis.operations.queries.push({
            name: field.name,
            description: field.description,
            arguments: field.args.map((arg: any) => ({
              name: arg.name,
              description: arg.description,
              type: this.formatType(arg.type),
              required: arg.type.kind === 'NON_NULL',
            })),
            returnType: this.formatType(field.type),
          });
        }
      }

      // Mutation operations
      if (type.name === schema.mutationType?.name && type.fields) {
        for (const field of type.fields) {
          analysis.operations.mutations.push({
            name: field.name,
            description: field.description,
            arguments: field.args.map((arg: any) => ({
              name: arg.name,
              description: arg.description,
              type: this.formatType(arg.type),
              required: arg.type.kind === 'NON_NULL',
            })),
            returnType: this.formatType(field.type),
          });
        }
      }

      // Template types (start with _)
      if (type.name.startsWith('_') && type.kind === 'OBJECT') {
        analysis.templateTypes.push({
          name: type.name,
          description: type.description,
          fields: type.fields?.map((f: any) => f.name) || [],
        });
      }

      // Input types
      if (type.kind === 'INPUT_OBJECT') {
        analysis.inputTypes.push({
          name: type.name,
          description: type.description,
          fields:
            type.inputFields?.map((f: any) => ({
              name: f.name,
              type: this.formatType(f.type),
            })) || [],
        });
      }

      // Other custom types
      if (
        type.kind === 'OBJECT' &&
        !type.name.startsWith('_') &&
        type.name !== schema.queryType?.name &&
        type.name !== schema.mutationType?.name &&
        type.name !== schema.subscriptionType?.name
      ) {
        analysis.customTypes.push({
          name: type.name,
          description: type.description,
          kind: type.kind,
          fieldCount: type.fields?.length || 0,
        });
      }
    }

    return analysis;
  }

  /**
   * Format GraphQL type for display
   */
  private formatType(type: any): string {
    if (!type) return 'Unknown';

    if (type.kind === 'NON_NULL') {
      return this.formatType(type.ofType) + '!';
    }

    if (type.kind === 'LIST') {
      return '[' + this.formatType(type.ofType) + ']';
    }

    return type.name || 'Unknown';
  }

  /**
   * Parse natural language /sitecore command
   * Enhanced with better pattern matching and more commands
   */
  async parseSitecoreCommand(command: string): Promise<any> {
    const lowerCommand = command.toLowerCase().trim();

    // Remove /sitecore prefix if present
    const cleanCommand = lowerCommand.replace(/^\/sitecore\s+/, '');

    // Help command
    if (cleanCommand === 'help' || cleanCommand === '?' || cleanCommand === '') {
      return {
        action: 'help',
        examples: [
          '/sitecore get item /sitecore/content/Home',
          '/sitecore get /sitecore/content/Home version 2',
          '/sitecore search articles',
          '/sitecore search for "home page" in /sitecore/content',
          '/sitecore children of /sitecore/content',
          '/sitecore field Title from /sitecore/content/Home',
          '/sitecore templates',
          '/sitecore sites',
          '/sitecore create item MyItem with template Sample/Article under /sitecore/content',
          '/sitecore update item /sitecore/content/Home name "New Home"',
          '/sitecore delete item /sitecore/content/OldItem',
          '/sitecore scan schema',
          '/sitecore examples',
          '/sitecore help',
        ],
      };
    }

    // Examples command
    if (cleanCommand === 'examples') {
      return {
        action: 'examples',
        categories: [
          {
            category: 'Basic Item Operations',
            examples: [
              {
                command: '/sitecore get item /sitecore/content/Home',
                description: 'Get an item by path',
              },
              {
                command: '/sitecore get /sitecore/content/Home',
                description: 'Short syntax for get item',
              },
              {
                command: '/sitecore /sitecore/content/Home',
                description: 'Even shorter - just the path',
              },
              {
                command: '/sitecore children of /sitecore/content',
                description: 'Get all children',
              },
              {
                command: '/sitecore field Title from /sitecore/content/Home',
                description: 'Get specific field value',
              },
            ],
          },
          {
            category: 'Search Operations',
            examples: [
              { command: '/sitecore search articles', description: 'Simple keyword search' },
              { command: '/sitecore search for "home page"', description: 'Search with quotes' },
              {
                command: '/sitecore find items with template Article',
                description: 'Search by template',
              },
              {
                command: '/sitecore search articles in /sitecore/content',
                description: 'Search in specific path',
              },
            ],
          },
          {
            category: 'Templates & Schema',
            examples: [
              { command: '/sitecore templates', description: 'List all templates' },
              { command: '/sitecore scan schema', description: 'Analyze GraphQL schema' },
              { command: '/sitecore sites', description: 'List all sites' },
            ],
          },
          {
            category: 'Mutations (requires write permissions)',
            examples: [
              {
                command:
                  '/sitecore create item MyItem with template {GUID} under /sitecore/content',
                description: 'Create new item',
              },
              {
                command: '/sitecore update item /sitecore/content/Home name "New Name"',
                description: 'Update item name',
              },
              {
                command: '/sitecore delete item /sitecore/content/OldItem',
                description: 'Delete item',
              },
            ],
          },
        ],
      };
    }

    // Scan schema command
    if (cleanCommand.includes('scan') || cleanCommand.includes('schema')) {
      const analysis = await this.analyzeSchema();
      return {
        action: 'schema_scan',
        result: analysis,
      };
    }

    // List templates command
    if (
      cleanCommand === 'templates' ||
      cleanCommand === 'list templates' ||
      cleanCommand === 'show templates'
    ) {
      const templates = await this.getTemplates();
      return {
        action: 'list_templates',
        result: {
          count: templates.length,
          templates: templates.slice(0, 20).map((t: any) => ({
            name: t.name,
            path: t.path,
            id: t.id,
          })),
          note:
            templates.length > 20
              ? `Showing first 20 of ${templates.length} templates. Use the API for full access.`
              : null,
        },
      };
    }

    // List sites command
    if (
      cleanCommand === 'sites' ||
      cleanCommand === 'list sites' ||
      cleanCommand === 'show sites'
    ) {
      try {
        const sites = await this.getSites();
        return {
          action: 'list_sites',
          result: {
            count: sites.length,
            sites: sites.map((s: any) => ({
              name: s.name,
              hostName: s.hostName,
              database: s.database,
              language: s.language,
            })),
          },
        };
      } catch (_error) {
        return {
          action: 'list_sites',
          error:
            'Sites query returned no data. This might not be configured in your Sitecore instance.',
          result: { count: 0, sites: [] },
        };
      }
    }

    // Get item with version support
    // Patterns: "get item PATH", "get PATH", "PATH", "get item PATH version N", "get PATH version N"
    const getItemVersionMatch = cleanCommand.match(
      /(?:get\s+(?:item\s+)?)?([\/\w-]+)\s+version\s+(\d+)/
    );
    if (getItemVersionMatch) {
      const path = getItemVersionMatch[1].trim();
      const version = parseInt(getItemVersionMatch[2]);
      const item = await this.getItem(path, 'en', 'master', version);
      return {
        action: 'get_item',
        result: item,
        note: `Retrieved version ${version} of item`,
      };
    }

    // Get item (various patterns)
    const getItemMatch = cleanCommand.match(
      /^(?:get\s+(?:item\s+)?)?([\/].+?)(?:\s+(?:from|in)\s+.+)?$/
    );
    if (getItemMatch && !cleanCommand.includes('search') && !cleanCommand.includes('field')) {
      const path = getItemMatch[1].trim();
      const item = await this.getItem(path);
      return {
        action: 'get_item',
        result: item,
      };
    }

    // Search with template filter
    // Pattern: "find items with template TEMPLATE", "search items with template TEMPLATE"
    const searchTemplateMatch = cleanCommand.match(
      /(?:find|search)\s+(?:items\s+)?(?:with|by)\s+template\s+(.+)/
    );
    if (searchTemplateMatch) {
      const templateName = searchTemplateMatch[1].trim();
      const results = await this.searchItems(undefined, undefined, templateName);
      return {
        action: 'search',
        result: results,
        note: `Found items with template: ${templateName}`,
      };
    }

    // Search with path context
    // Pattern: "search KEYWORD in PATH", "search for KEYWORD in PATH"
    const searchInPathMatch = cleanCommand.match(
      /search\s+(?:for\s+)?["\']?(.+?)["\']?\s+in\s+([\/].+)/
    );
    if (searchInPathMatch) {
      const searchText = searchInPathMatch[1].trim();
      const rootPath = searchInPathMatch[2].trim();
      const results = await this.searchItems(searchText, rootPath);
      return {
        action: 'search',
        result: results,
        note: `Searching for "${searchText}" in ${rootPath}`,
      };
    }

    // Simple search command
    // Pattern: "search KEYWORD", "search for KEYWORD", "find KEYWORD"
    const searchMatch = cleanCommand.match(/(?:search|find)\s+(?:for\s+)?["\']?(.+?)["\']?$/);
    if (searchMatch) {
      const searchText = searchMatch[1].trim();
      const results = await this.searchItems(searchText);
      return {
        action: 'search',
        result: results,
      };
    }

    // Children command (various patterns)
    // Pattern: "children of PATH", "children PATH", "list children of PATH"
    const childrenMatch = cleanCommand.match(/(?:list\s+)?children\s+(?:of\s+)?([\/].+)/);
    if (childrenMatch) {
      const path = childrenMatch[1].trim();
      const children = await this.getChildren(path);
      return {
        action: 'get_children',
        result: children,
      };
    }

    // Field command (various patterns)
    // Pattern: "field FIELD from PATH", "get field FIELD from PATH", "show field FIELD from PATH"
    const fieldMatch = cleanCommand.match(
      /(?:get\s+|show\s+)?field\s+(\w+)\s+(?:from|of|in)\s+([\/].+)/
    );
    if (fieldMatch) {
      const fieldName = fieldMatch[1].trim();
      const path = fieldMatch[2].trim();
      const field = await this.getFieldValue(path, fieldName);
      return {
        action: 'get_field',
        result: field,
      };
    }

    // Create item command
    // Pattern: "create item NAME with template TEMPLATE under PARENT"
    const createMatch = cleanCommand.match(
      /create\s+(?:item\s+)?(\w+)\s+(?:with\s+)?template\s+([^\s]+)\s+(?:under|in|at)\s+([\/].+)/
    );
    if (createMatch) {
      const name = createMatch[1].trim();
      const template = createMatch[2].trim();
      const parent = createMatch[3].trim();
      try {
        const result = await this.createItem(name, template, parent);
        return {
          action: 'create_item',
          result: result,
          note: `Created item "${name}" at ${result.path}`,
        };
      } catch (error: any) {
        return {
          action: 'create_item',
          error: error.message,
          note: 'Item creation failed. This requires write permissions on the API key.',
        };
      }
    }

    // Update item command
    // Pattern: "update item PATH name NAME", "update PATH name NAME"
    const updateMatch = cleanCommand.match(
      /update\s+(?:item\s+)?([\/][^\s]+)\s+name\s+["\']?(.+?)["\']?$/
    );
    if (updateMatch) {
      const path = updateMatch[1].trim();
      const newName = updateMatch[2].trim();
      try {
        const result = await this.updateItem(path, 'en', undefined, newName);
        return {
          action: 'update_item',
          result: result,
          note: `Updated item name to "${newName}"`,
        };
      } catch (error: any) {
        return {
          action: 'update_item',
          error: error.message,
          note: 'Item update failed. This requires write permissions on the API key.',
        };
      }
    }

    // Delete item command
    // Pattern: "delete item PATH", "delete PATH", "remove item PATH"
    const deleteMatch = cleanCommand.match(/(?:delete|remove)\s+(?:item\s+)?([\/].+)/);
    if (deleteMatch) {
      const path = deleteMatch[1].trim();
      try {
        const result = await this.deleteItem(path);
        return {
          action: 'delete_item',
          result: { success: result, path: path },
          note: result ? `Item deleted: ${path}` : `Item deletion failed: ${path}`,
        };
      } catch (error: any) {
        return {
          action: 'delete_item',
          error: error.message,
          note: 'Item deletion failed. This requires write permissions on the API key.',
        };
      }
    }

    // Unknown command - provide smart suggestions
    return {
      action: 'unknown',
      message:
        'Unknown command. Type "/sitecore help" or "/sitecore examples" for available commands.',
      input: command,
      suggestions: [
        'Try: /sitecore get item /sitecore/content/Home',
        'Try: /sitecore search articles',
        'Try: /sitecore children of /sitecore/content',
        'Try: /sitecore help',
      ],
    };
  }

  /**
   * Get parent item
   * NEW FEATURE: Navigate up the item tree
   */
  async getParent(
    path: string,
    language: string = 'en',
    version?: number
  ): Promise<SitecoreItem | null> {
    const query = `
      query GetParent($path: String!, $language: String!, $version: Int) {
        item(path: $path, language: $language, version: $version) {
          parent {
            id
            name
            displayName
            path
            template {
              id
              name
            }
            hasChildren
          }
        }
      }
    `;

    const result = await this.executeGraphQL(query, { path, language, version });

    if (!result.item || !result.item.parent) {
      return null; // Root item has no parent
    }

    const parent = result.item.parent;
    return {
      id: parent.id,
      name: parent.name,
      displayName: parent.displayName,
      path: parent.path,
      templateId: parent.template.id,
      templateName: parent.template.name,
      language: language,
      version: version || 1,
      hasChildren: parent.hasChildren,
      fields: {},
    };
  }

  /**
   * Get all ancestors (parent, grandparent, etc.) up to root
   * NEW FEATURE: Complete path traversal
   */
  async getAncestors(
    path: string,
    language: string = 'en',
    version?: number
  ): Promise<SitecoreItem[]> {
    const ancestors: SitecoreItem[] = [];
    let currentPath = path;

    while (true) {
      const parent = await this.getParent(currentPath, language, version);
      if (!parent) break; // Reached root

      ancestors.push(parent);
      currentPath = parent.path;

      // Safety check to prevent infinite loops
      if (ancestors.length > 50) {
        throw new Error('Too many ancestors (max 50). Possible circular reference.');
      }
    }

    return ancestors;
  }

  /**
   * Get all versions of an item
   * NEW FEATURE: Version history
   */
  async getItemVersions(
    path: string,
    language: string = 'en'
  ): Promise<Array<{ version: number; item: SitecoreItem }>> {
    // Note: GraphQL doesn't have a direct "all versions" query
    // We need to query version by version until we get null
    const versions: Array<{ version: number; item: SitecoreItem }> = [];

    for (let v = 1; v <= 20; v++) {
      // Check up to 20 versions
      try {
        const item = await this.getItem(path, language, 'master', v);
        versions.push({ version: v, item });
      } catch (_error) {
        // Version doesn't exist, stop searching
        break;
      }
    }

    return versions;
  }

  /**
   * Get item with statistics (created/updated dates)
   * NEW FEATURE: Uses inline fragment for Statistics type
   * NOTE: created/updated are DateField objects with { value } property
   */
  async getItemWithStatistics(
    path: string,
    language: string = 'en',
    version?: number
  ): Promise<
    SitecoreItem & { created?: string; updated?: string; createdBy?: string; updatedBy?: string }
  > {
    const query = `
      query GetItemWithStats($path: String!, $language: String!, $version: Int) {
        item(path: $path, language: $language, version: $version) {
          id
          name
          displayName
          path
          template {
            id
            name
          }
          hasChildren
          ... on Statistics {
            created {
              value
            }
            updated {
              value
            }
            createdBy {
              value
            }
            updatedBy {
              value
            }
          }
        }
      }
    `;

    const result = await this.executeGraphQL(query, { path, language, version });

    if (!result.item) {
      throw new Error(`Item not found: ${path}`);
    }

    const item = result.item;
    return {
      id: item.id,
      name: item.name,
      displayName: item.displayName,
      path: item.path,
      templateId: item.template.id,
      templateName: item.template.name,
      language: language,
      version: version || 1,
      hasChildren: item.hasChildren,
      fields: {},
      created: item.created?.value,
      updated: item.updated?.value,
      createdBy: item.createdBy?.value,
      updatedBy: item.updatedBy?.value,
    };
  }

  /**
   * COMPREHENSIVE DISCOVERY: Get item with ALL dependencies
   *
   * NEW FEATURE v1.6.0!
   *
   * Automatically discovers and returns:
   * 1. Content item details
   * 2. Template with full inheritance chain
   * 3. All fields from template hierarchy
   * 4. Renderings associated with template or item
   * 5. GraphQL resolvers for those renderings
   *
   * This enables AI-assisted editing with complete context of what belongs to a content item.
   *
   * WORKFLOW:
   * - Get content item (nl-NL or specified language)
   * - Extract template ID
   * - Get template definition (ALWAYS 'en' language)
   * - Follow template inheritance (base templates recursively)
   * - Get all fields from template hierarchy
   * - Search for renderings (if enabled)
   * - Find resolvers (if enabled)
   *
   * @param path - Content item path or ID
   * @param language - Content language (default: nl-NL)
   * @param includeRenderings - Include renderings (default: true)
   * @param includeResolvers - Include resolvers (default: true)
   */
  async discoverItemDependencies(
    path: string,
    language: string = 'nl-NL',
    includeRenderings: boolean = false,
    includeResolvers: boolean = false,
    progressCallback?: (step: number, message: string) => void
  ): Promise<{
    item: SitecoreItem;
    template: any;
    templateInheritance: any[];
    fields: any[];
    renderings?: any[];
    resolvers?: any[];
    summary: {
      itemName: string;
      itemPath: string;
      itemLanguage: string;
      templateName: string;
      templatePath: string;
      totalFields: number;
      inheritanceDepth: number;
      renderingCount?: number;
      resolverCount?: number;
    };
  }> {
    try {
      progressCallback?.(1, 'Getting content item...');
      console.log(`[Discovery] Step 1: Getting content item...`);
      // STEP 1: Get content item (in specified language)
      const item = await this.getItem(path, language);
      console.log(`[Discovery] Step 1 complete: ${item?.name}`);
      progressCallback?.(1, `Content item retrieved: ${item?.name}`);

      if (!item) {
        throw new Error(`Item not found: ${path} (language: ${language})`);
      }

      progressCallback?.(2, 'Getting template definition...');
      console.log(`[Discovery] Step 2: Getting template definition...`);
      // STEP 2: Get template definition (ALWAYS 'en' for templates)
      // SOLUTION: Template items ARE regular items, just query them in 'en' language
      // CRITICAL: Format GUID with dashes - GraphQL returns without dashes but requires them in queries
      const templateId = this.formatGuid(item.templateId);
      const _templateName = item.templateName;
      let template: any = null;
      const templateInheritance: any[] = [];

      try {
        // Templates are just items in 'en' language
        // Use getItem() which works for all items including templates
        const templateItem = await this.getItem(templateId, 'en');

        if (templateItem) {
          console.log(`[Discovery] Step 2: Template found: ${templateItem.name}`);
          progressCallback?.(2, `Template retrieved: ${templateItem.name}`);
          // Get all template fields
          const templateFields = await this.getItemFieldsFromTemplate(templateId, 'en');
          console.log(`[Discovery] Step 2: Retrieved ${templateFields.length} template fields`);
          progressCallback?.(2, `Template has ${templateFields.length} fields`);

          template = {
            id: templateItem.id,
            name: templateItem.name,
            displayName: templateItem.displayName,
            path: templateItem.path,
            template: {
              id: templateItem.templateId,
              name: templateItem.templateName,
            },
            hasChildren: templateItem.hasChildren,
            fields: templateFields.map((f) => ({ name: f.name, value: f.value })),
          };

          progressCallback?.(3, 'Checking template inheritance...');
          console.log(`[Discovery] Step 3: Checking template inheritance...`);
          // STEP 3: Follow template inheritance (base templates)
          // Get base templates from __Base template field
          const baseTemplatesField = template.fields?.find(
            (f: any) => f.name === '__Base template'
          );

          if (baseTemplatesField && baseTemplatesField.value) {
            // Parse base template IDs (pipe-separated)
            // CRITICAL: Format each GUID properly with dashes
            const baseTemplateIds = baseTemplatesField.value
              .split('|')
              .filter((id: string) => id.trim())
              .map((id: string) => this.formatGuid(id));

            console.log(`[Discovery] Step 3: Found ${baseTemplateIds.length} base template(s)`);
            progressCallback?.(
              3,
              `Found ${baseTemplateIds.length} base template(s), retrieving...`
            );
            // Get each base template as a regular item (ALWAYS 'en' language)
            for (const baseId of baseTemplateIds) {
              try {
                const baseTemplateItem = await this.getItem(baseId, 'en');
                if (baseTemplateItem) {
                  console.log(
                    `[Discovery] Step 3: Retrieved base template: ${baseTemplateItem.name}`
                  );
                }

                if (baseTemplateItem) {
                  templateInheritance.push({
                    id: baseTemplateItem.id,
                    name: baseTemplateItem.name,
                    displayName: baseTemplateItem.displayName,
                    path: baseTemplateItem.path,
                    template: {
                      id: baseTemplateItem.templateId,
                      name: baseTemplateItem.templateName,
                    },
                  });
                }
              } catch (_error) {
                // Skip if base template not found
                console.error(`Base template not found: ${baseId}`);
              }
            }
            progressCallback?.(3, `Retrieved ${templateInheritance.length} base template(s)`);
          }
        }
      } catch (_error) {
        console.error(`Template not found: ${templateId}`);
      }

      progressCallback?.(4, 'Getting all item fields...');
      console.log(`[Discovery] Step 4: Getting all item fields...`);
      // STEP 4: Get all fields (from item)
      const fieldsArray = await this.getItemFieldsFromTemplate(path, language);
      const totalFields = fieldsArray.length;
      console.log(`[Discovery] Step 4 complete: ${totalFields} fields`);
      progressCallback?.(4, `Retrieved ${totalFields} fields`);

      // STEP 5: Search for renderings (if enabled)
      let renderings: any[] = [];

      if (includeRenderings && template) {
        progressCallback?.(5, 'Searching for renderings (this may take a while)...');
        console.log(`[Discovery] Step 5: Searching for renderings (this may take a while)...`);
        try {
          // Search for renderings in /sitecore/layout/Renderings
          // Filter by template name (Feature/Module pattern)
          const renderingSearch = await this.searchItems(
            template.name, // searchText
            '/sitecore/layout/Renderings', // rootPath
            undefined, // templateName filter
            'en', // language
            'master', // database
            50 // maxItems
          );

          renderings = renderingSearch || [];
          console.log(`[Discovery] Step 5 complete: Found ${renderings.length} rendering(s)`);
          progressCallback?.(5, `Found ${renderings.length} rendering(s)`);
        } catch (error) {
          console.error('[Discovery] Step 5 error: Error searching for renderings', error);
        }
      } else {
        console.log(`[Discovery] Step 5: Skipped (includeRenderings=false)`);
        progressCallback?.(5, 'Skipped renderings (disabled)');
      }

      // STEP 6: Find resolvers (if enabled)
      let resolvers: any[] = [];

      if (includeResolvers && renderings.length > 0) {
        progressCallback?.(6, 'Searching for resolvers (this may take a while)...');
        console.log(`[Discovery] Step 6: Searching for resolvers (this may take a while)...`);
        try {
          // Search for resolvers in /sitecore/system/Modules/Layout Service/Rendering Contents Resolvers
          const resolverSearch = await this.searchItems(
            template?.name || '', // searchText
            '/sitecore/system/Modules/Layout Service/Rendering Contents Resolvers', // rootPath
            undefined, // templateName filter
            'en', // language
            'master', // database
            50 // maxItems
          );

          resolvers = resolverSearch || [];
          console.log(`[Discovery] Step 6 complete: Found ${resolvers.length} resolver(s)`);
          progressCallback?.(6, `Found ${resolvers.length} resolver(s)`);
        } catch (error) {
          console.error('[Discovery] Step 6 error: Error searching for resolvers', error);
        }
      } else {
        console.log(`[Discovery] Step 6: Skipped (includeResolvers=false or no renderings)`);
        progressCallback?.(6, 'Skipped resolvers (disabled or no renderings)');
      }

      progressCallback?.(7, 'Building summary...');
      console.log(`[Discovery] Step 7: Building summary...`);
      // STEP 7: Build summary
      const summary = {
        itemName: item.name,
        itemPath: item.path,
        itemLanguage: language,
        templateName: template?.name || 'Unknown',
        templatePath: template?.path || 'Unknown',
        totalFields: totalFields,
        inheritanceDepth: templateInheritance.length,
        ...(includeRenderings && { renderingCount: renderings.length }),
        ...(includeResolvers && { resolverCount: resolvers.length }),
      };

      console.log(`[Discovery] Complete! Summary:`, summary);
      progressCallback?.(7, 'Discovery complete!');
      return {
        item,
        template,
        templateInheritance,
        fields: fieldsArray,
        ...(includeRenderings && { renderings }),
        ...(includeResolvers && { resolvers }),
        summary,
      };
    } catch (error) {
      console.error('[Discovery] Error:', error);
      throw new Error(
        `Error discovering item dependencies: ${error instanceof Error ? error.message : String(error)}`
      );
    }
  }
}
