#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListPromptsRequestSchema,
  GetPromptRequestSchema,
  ErrorCode,
  McpError,
} from '@modelcontextprotocol/sdk/types.js';
import { SitecoreService } from './sitecore-service.js';

// Configuration
const SITECORE_HOST = process.env.SITECORE_HOST || 'https://your-sitecore-instance.com';
const SITECORE_ENDPOINT =
  process.env.SITECORE_ENDPOINT || `${SITECORE_HOST}/sitecore/api/graph/items/master`;
const SITECORE_API_KEY = process.env.SITECORE_API_KEY;
const SITECORE_USERNAME = process.env.SITECORE_USERNAME || '';
const SITECORE_PASSWORD = process.env.SITECORE_PASSWORD || '';

if (!SITECORE_API_KEY) {
  console.error('ERROR: SITECORE_API_KEY environment variable is required');
  console.error('Please set it in your .env file or MCP client configuration');
  process.exit(1);
}

// Initialize Sitecore service
const sitecoreService = new SitecoreService(
  SITECORE_HOST,
  SITECORE_USERNAME,
  SITECORE_PASSWORD,
  SITECORE_API_KEY,
  SITECORE_ENDPOINT
);

// Create MCP server
const server = new Server(
  {
    name: 'sitecore-mcp-server',
    version: '1.3.0',
  },
  {
    capabilities: {
      tools: {},
      prompts: {},
    },
  }
);

// List available prompts
server.setRequestHandler(ListPromptsRequestSchema, async () => {
  return {
    prompts: [
      {
        name: 'sitecore',
        description:
          '🔧 Sitecore command interface - Type natural language commands to interact with Sitecore',
        arguments: [
          {
            name: 'command',
            description:
              "Your Sitecore command (e.g., 'get item /sitecore/content/Home', 'search articles', 'help')",
            required: false,
          },
        ],
      },
      {
        name: 'tool-selection-guide',
        description:
          '📚 AI Tool Selection Rules for Sitecore MCP',
        arguments: [],
      },
    ],
  };
});

// Get prompt
server.setRequestHandler(GetPromptRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === 'sitecore') {
    const command = args?.command || 'help';

    return {
      messages: [
        {
          role: 'user',
          content: {
            type: 'text',
            text: `/sitecore ${command}`,
          },
        },
      ],
    };
  }

  if (name === 'tool-selection-guide') {
    return {
      messages: [
        {
          role: 'user',
          content: {
            type: 'text',
            text: `# Sitecore MCP Tool Selection Rules

## 🎯 CRITICAL RULES:

### When user asks about "children", "child items", "sub-items":
✅ USE: sitecore_get_children
❌ DO NOT USE: sitecore_query

Examples:
- "get children of /sitecore/content/Home" → sitecore_get_children
- "show me child items under {GUID}" → sitecore_get_children
- "what are the children" → sitecore_get_children
- "list sub-items" → sitecore_get_children

### When user explicitly mentions "query" or needs XPath/fast query:
✅ USE: sitecore_query
❌ DO NOT USE: sitecore_get_children

Examples:
- "run query /sitecore/content//*[@@templatename='Page']" → sitecore_query
- "execute fast query" → sitecore_query
- "query for all articles" → sitecore_query

### When user asks to "search" or "find":
✅ USE: sitecore_search (with filters)
❌ DO NOT USE: sitecore_query or sitecore_get_children

Examples:
- "search for items with name Home" → sitecore_search
- "find all Page templates" → sitecore_search

### Input formats supported:
- Path: /sitecore/content/Home
- GUID with braces: {AAAB4C4D-0589-4F84-8CE4-D4DF3DF3F8DF}
- GUID without braces: AAAB4C4D-0589-4F84-8CE4-D4DF3DF3F8DF
- GUID with dashes: AAAB4C4D-0589-4F84-8CE4-D4DF3DF3F8DF

All tools that accept 'path' parameter can also accept GUID format.

## 🌍 LANGUAGE HANDLING:

### When item is not found:
The system will automatically check which languages the item exists in and suggest them.

Error message will show:
- "Item exists in: en, nl-NL, de-DE. Try one of these languages."
- AI should retry the request with one of the suggested languages

### Best practice:
1. First attempt with default/requested language
2. If error shows available languages, retry with suggested language
3. Inform user which language was used to retrieve the item

Example workflow:
- User: "get item /sitecore/content/Home"
- First try: language=en → Error: "Item exists in: nl-NL, de-DE"
- Retry: language=nl-NL → Success
- Response: "Retrieved item in Dutch (nl-NL)"`,
          },
        },
      ],
    };
  }

  throw new McpError(ErrorCode.InvalidRequest, `Unknown prompt: ${name}`);
});

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'sitecore_get_item',
        description:
          'Get a Sitecore item by path or ID. Returns item properties including fields, template info, and metadata. NEW: Supports version parameter for /items/master endpoint.',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Sitecore item path (e.g., /sitecore/content/Home) or item ID (GUID)',
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
            database: {
              type: 'string',
              description: 'Database name (master, web, core)',
              default: 'master',
            },
            version: {
              type: 'number',
              description: 'Item version number (optional, for /items/master endpoint)',
            },
          },
          required: ['path'],
        },
      },
      {
        name: 'sitecore_get_children',
        description:
          '🎯 PRIMARY TOOL for getting child/children items. Use this when the user asks about "children", "child items", "sub-items", or "items under/in" a path. Supports both path and GUID input. NEW: Supports version parameter. DO NOT use sitecore_query for simple children requests.',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Sitecore item path or item ID',
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
            database: {
              type: 'string',
              description: 'Database name (master, web, core)',
              default: 'master',
            },
            recursive: {
              type: 'boolean',
              description: 'Get all descendants recursively',
              default: false,
            },
            version: {
              type: 'number',
              description: 'Item version number (optional)',
            },
          },
          required: ['path'],
        },
      },
      {
        name: 'sitecore_query',
        description: '⚠️ ADVANCED TOOL - Use ONLY when user explicitly mentions "query" or needs XPath-like fast query syntax (e.g., /sitecore/content//*[@@templatename=\'Article\']). For simple "get children" requests, use sitecore_get_children instead.',
        inputSchema: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description:
                "Sitecore query (e.g., /sitecore/content/Home//*[@@templatename='Article'])",
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
            database: {
              type: 'string',
              description: 'Database name (master, web, core)',
              default: 'master',
            },
            maxItems: {
              type: 'number',
              description: 'Maximum number of items to return (default: 100)',
              default: 100,
            },
          },
          required: ['query'],
        },
      },
      {
        name: 'sitecore_search',
        description:
          'Search for Sitecore items with ENHANCED FILTERING and ORDERING. NEW: Supports path_contains, path_starts_with, name_contains, template_in, hasChildren, hasLayout filters PLUS orderBy (sort by name, displayName, path) plus facets, field filtering, index selection, and version filtering for /items/master endpoint.',
        inputSchema: {
          type: 'object',
          properties: {
            searchText: {
              type: 'string',
              description: 'Keyword to search for in items (optional)',
            },
            rootPath: {
              type: 'string',
              description: 'Root path to start search from (optional)',
            },
            templateName: {
              type: 'string',
              description: 'Filter by template name (optional)',
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
            database: {
              type: 'string',
              description: 'Database name (master, web, core)',
              default: 'master',
            },
            maxItems: {
              type: 'number',
              description: 'Maximum number of items to return (default: 50)',
              default: 50,
            },
            index: {
              type: 'string',
              description: "Search index name (optional, e.g. 'sitecore_master_index')",
            },
            latestVersion: {
              type: 'boolean',
              description: 'Only return latest versions (optional)',
            },
            pathContains: {
              type: 'string',
              description: 'Filter items where path contains this string (case-insensitive)',
            },
            pathStartsWith: {
              type: 'string',
              description: 'Filter items where path starts with this string (case-insensitive)',
            },
            nameContains: {
              type: 'string',
              description: 'Filter items where name contains this string (case-insensitive)',
            },
            templateIn: {
              type: 'array',
              items: { type: 'string' },
              description:
                'Filter items by template names (OR logic - item matches any template in array)',
            },
            hasChildrenFilter: {
              type: 'boolean',
              description:
                'Filter items by hasChildren property (true = only items with children, false = only items without children)',
            },
            hasLayoutFilter: {
              type: 'boolean',
              description:
                'Filter items by hasLayout (true = only items with layout defined, false = only items without layout)',
            },
          },
        },
      },
      {
        name: 'sitecore_search_paginated',
        description:
          "Search for Sitecore items WITH PAGINATION, ENHANCED FILTERING, and ORDERING. Returns items plus pagination metadata (pageInfo with cursors, totalCount). Supports path_contains, path_starts_with, name_contains, template_in, hasChildren, hasLayout filters PLUS orderBy (sort by name, displayName, path). Use 'endCursor' from response as 'after' parameter for next page.",
        inputSchema: {
          type: 'object',
          properties: {
            searchText: {
              type: 'string',
              description: 'Keyword to search for in items (optional)',
            },
            rootPath: {
              type: 'string',
              description: 'Root path to start search from (optional)',
            },
            templateName: {
              type: 'string',
              description: 'Filter by template name (optional)',
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
            database: {
              type: 'string',
              description: 'Database name (master, web, core)',
              default: 'master',
            },
            maxItems: {
              type: 'number',
              description: 'Maximum number of items to return per page (default: 50)',
              default: 50,
            },
            index: {
              type: 'string',
              description: "Search index name (optional, e.g. 'sitecore_master_index')",
            },
            latestVersion: {
              type: 'boolean',
              description: 'Only return latest versions (optional)',
            },
            after: {
              type: 'string',
              description:
                "Cursor value for pagination (get results after this cursor). Use 'endCursor' from previous response to get next page.",
            },
            pathContains: {
              type: 'string',
              description: 'Filter items where path contains this string (case-insensitive)',
            },
            pathStartsWith: {
              type: 'string',
              description: 'Filter items where path starts with this string (case-insensitive)',
            },
            nameContains: {
              type: 'string',
              description: 'Filter items where name contains this string (case-insensitive)',
            },
            templateIn: {
              type: 'array',
              items: { type: 'string' },
              description:
                'Filter items by template names (OR logic - item matches any template in array)',
            },
            hasChildrenFilter: {
              type: 'boolean',
              description:
                'Filter items by hasChildren property (true = only items with children, false = only items without children)',
            },
            hasLayoutFilter: {
              type: 'boolean',
              description:
                'Filter items by hasLayout (true = only items with layout defined, false = only items without layout)',
            },
            orderBy: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  field: {
                    type: 'string',
                    enum: ['name', 'displayName', 'path'],
                    description: 'Field to sort by',
                  },
                  direction: {
                    type: 'string',
                    enum: ['ASC', 'DESC'],
                    description: 'Sort direction (ASC = ascending, DESC = descending)',
                  },
                },
                required: ['field', 'direction'],
              },
              description:
                "Sort results by one or more fields. Multiple sort fields are applied in order (e.g., [{field: 'path', direction: 'ASC'}, {field: 'name', direction: 'ASC'}])",
            },
          },
        },
      },
      {
        name: 'sitecore_get_field_value',
        description:
          'Get a specific field value from a Sitecore item. NEW: Supports version parameter.',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Sitecore item path or item ID',
            },
            fieldName: {
              type: 'string',
              description: 'Name of the field to retrieve',
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
            database: {
              type: 'string',
              description: 'Database name (master, web, core)',
              default: 'master',
            },
            version: {
              type: 'number',
              description: 'Item version number (optional)',
            },
          },
          required: ['path', 'fieldName'],
        },
      },
      {
        name: 'sitecore_get_template',
        description: 'Get template information including all fields and sections.',
        inputSchema: {
          type: 'object',
          properties: {
            templatePath: {
              type: 'string',
              description: 'Template path or template ID',
            },
            database: {
              type: 'string',
              description: 'Database name (master, web, core)',
              default: 'master',
            },
          },
          required: ['templatePath'],
        },
      },
      {
        name: 'sitecore_get_item_fields',
        description:
          "Get ALL fields with values for an item (based on template definition). NEW: Template-aware field discovery! When asked 'what fields does item X have', use this tool. Includes inherited fields from base templates (Helix).",
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Sitecore item path or item ID',
            },
            language: {
              type: 'string',
              description:
                "Language code (optional, smart default: 'en' for templates/system, site language for content)",
            },
            version: {
              type: 'number',
              description: 'Item version number (optional, defaults to latest)',
            },
          },
          required: ['path'],
        },
      },
      {
        name: 'sitecore_get_layout',
        description:
          'Get layout/presentation information for a Sitecore route including placeholders and renderings. Uses site name and route path.',
        inputSchema: {
          type: 'object',
          properties: {
            site: {
              type: 'string',
              description: "Site name (e.g., 'website')",
            },
            routePath: {
              type: 'string',
              description: "Route path (e.g., '/home', '/about')",
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
          },
          required: ['site', 'routePath'],
        },
      },
      {
        name: 'sitecore_get_sites',
        description:
          'Get Sitecore site configurations with filtering. NEW for /items/master: Supports filtering by name, current site, and system sites.',
        inputSchema: {
          type: 'object',
          properties: {
            name: {
              type: 'string',
              description: 'Filter by site name (optional)',
            },
            current: {
              type: 'boolean',
              description: 'Get current site only (optional)',
            },
            includeSystemSites: {
              type: 'boolean',
              description: 'Include system sites (optional, default: false)',
            },
          },
        },
      },
      {
        name: 'sitecore_get_templates',
        description:
          'Get Sitecore templates with all fields and sections. NEW for /items/master: Direct template access!',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description:
                "Template path to filter (optional, e.g., '/sitecore/templates/User Defined')",
            },
          },
        },
      },
      {
        name: 'sitecore_create_item',
        description: 'Create a new Sitecore item. NEW for /items/master: Mutation support!',
        inputSchema: {
          type: 'object',
          properties: {
            name: {
              type: 'string',
              description: 'Item name',
            },
            template: {
              type: 'string',
              description: 'Template path or ID',
            },
            parent: {
              type: 'string',
              description: 'Parent item path or ID',
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
          },
          required: ['name', 'template', 'parent'],
        },
      },
      {
        name: 'sitecore_update_item',
        description: 'Update an existing Sitecore item. NEW for /items/master: Mutation support!',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Item path or ID',
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
            version: {
              type: 'number',
              description: 'Item version number (optional)',
            },
            name: {
              type: 'string',
              description: 'New item name (optional)',
            },
          },
          required: ['path'],
        },
      },
      {
        name: 'sitecore_delete_item',
        description: 'Delete a Sitecore item. NEW for /items/master: Mutation support!',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Item path or ID to delete',
            },
            deletePermanently: {
              type: 'boolean',
              description: 'Delete permanently (true) or move to recycle bin (false, default)',
              default: false,
            },
          },
          required: ['path'],
        },
      },
      {
        name: 'sitecore_scan_schema',
        description:
          'Scan and analyze the GraphQL schema to discover all available operations, types, and capabilities. Works with any GraphQL endpoint.',
        inputSchema: {
          type: 'object',
          properties: {
            saveToFile: {
              type: 'boolean',
              description: 'Save schema analysis to JSON file (default: true)',
              default: true,
            },
          },
        },
      },
      {
        name: 'sitecore_command',
        description:
          "Natural language interface to Sitecore. Ask questions or give commands in plain English. Examples: 'get item /sitecore/content/Home', 'search for articles', 'show me all templates', 'find items with template Page', 'scan the GraphQL schema', 'help with Sitecore queries'. This tool interprets your request and executes the appropriate Sitecore operation.",
        inputSchema: {
          type: 'object',
          properties: {
            command: {
              type: 'string',
              description:
                'Your natural language question or command about Sitecore. Be specific about what you want to retrieve, search for, or analyze.',
            },
          },
          required: ['command'],
        },
      },
      {
        name: 'sitecore_get_parent',
        description:
          'Get the parent item of a Sitecore item. Navigate up the item tree. NEW FEATURE!',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Sitecore item path or item ID',
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
            version: {
              type: 'number',
              description: 'Item version number (optional)',
            },
          },
          required: ['path'],
        },
      },
      {
        name: 'sitecore_get_ancestors',
        description:
          'Get all ancestors (parent, grandparent, etc.) up to the root. Complete path traversal. NEW FEATURE!',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Sitecore item path or item ID',
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
            version: {
              type: 'number',
              description: 'Item version number (optional)',
            },
          },
          required: ['path'],
        },
      },
      {
        name: 'sitecore_get_item_versions',
        description: 'Get all versions of a Sitecore item. Version history. NEW FEATURE!',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Sitecore item path or item ID',
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
          },
          required: ['path'],
        },
      },
      {
        name: 'sitecore_get_item_with_statistics',
        description:
          'Get a Sitecore item with statistics (created/updated dates and users). Uses Statistics inline fragment. NEW FEATURE!',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Sitecore item path or item ID',
            },
            language: {
              type: 'string',
              description: 'Language code (default: en)',
              default: 'en',
            },
            version: {
              type: 'number',
              description: 'Item version number (optional)',
            },
          },
          required: ['path'],
        },
      },
      {
        name: 'sitecore_discover_item_dependencies',
        description:
          'COMPREHENSIVE DISCOVERY: Get a content item with ALL its dependencies including template, inheritance chain, fields, renderings, and resolvers. Returns complete relationship graph. ⭐ NEW FEATURE v1.6.0!',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Sitecore content item path or item ID',
            },
            language: {
              type: 'string',
              description: 'Language code (default: nl-NL for content, en for templates)',
              default: 'nl-NL',
            },
            includeRenderings: {
              type: 'boolean',
              description:
                'Include renderings associated with template or item (default: false, can be slow)',
              default: false,
            },
            includeResolvers: {
              type: 'boolean',
              description: 'Include GraphQL resolvers for renderings (default: false, can be slow)',
              default: false,
            },
          },
          required: ['path'],
        },
      },
    ],
  };
});

// Handle tool execution
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (!args) {
    throw new McpError(ErrorCode.InvalidParams, 'Arguments are required');
  }

  try {
    switch (name) {
      case 'sitecore_get_item': {
        const progress = (m: string) => console.error(`[sitecore_get_item] ${m}`);
        progress(`Starting (path=${args.path}, language=${args.language || 'en'})`);
        const result = await sitecoreService.getItem(
          args.path as string,
          args.language as string,
          args.database as string,
          args.version as number | undefined
        );
        if (result) {
          progress(
            `Completed: ${result.name} (template=${result.templateName}, version=${result.version})`
          );
        } else {
          progress(`Completed: item not found`);
        }
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_get_children': {
        const progress = (m: string) => console.error(`[sitecore_get_children] ${m}`);
        progress(`Starting (path=${args.path}, language=${args.language || 'en'})`);
        const result = await sitecoreService.getChildren(
          args.path as string,
          args.language as string,
          args.database as string,
          args.recursive as boolean,
          args.version as number | undefined
        );
        const count = Array.isArray(result) ? result.length : 0;
        progress(`Completed: ${count} child(ren)`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_query': {
        const progress = (m: string) => console.error(`[sitecore_query] ${m}`);
        progress(`Starting GraphQL query`);
        const result = await sitecoreService.executeQuery(
          args.query as string,
          args.language as string,
          args.database as string,
          args.maxItems as number
        );
        progress(`Completed`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_search': {
        const progress = (m: string) => console.error(`[sitecore_search] ${m}`);
        progress(
          `Starting (text=${args.searchText || ''}, root=${args.rootPath || '/sitecore/content'}, lang=${args.language || 'en'})`
        );
        const filters: any = {};
        if (args.pathContains) filters.pathContains = args.pathContains;
        if (args.pathStartsWith) filters.pathStartsWith = args.pathStartsWith;
        if (args.nameContains) filters.nameContains = args.nameContains;
        if (args.templateIn) filters.templateIn = args.templateIn;
        if (args.hasChildrenFilter !== undefined)
          filters.hasChildrenFilter = args.hasChildrenFilter;
        if (args.hasLayoutFilter !== undefined) filters.hasLayoutFilter = args.hasLayoutFilter;

        const result = await sitecoreService.searchItems(
          args.searchText as string | undefined,
          args.rootPath as string | undefined,
          args.templateName as string | undefined,
          args.language as string,
          args.database as string,
          args.maxItems as number,
          args.index as string | undefined,
          undefined, // fieldsEqual - not yet implemented in UI
          undefined, // facetOn - not yet implemented in UI
          args.latestVersion as boolean | undefined,
          Object.keys(filters).length > 0 ? filters : undefined,
          args.orderBy as
            | Array<{ field: 'name' | 'displayName' | 'path'; direction: 'ASC' | 'DESC' }>
            | undefined
        );
        progress(`Completed: ${result.length} item(s)`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_search_paginated': {
        const progress = (m: string) => console.error(`[sitecore_search_paginated] ${m}`);
        progress(
          `Starting (text=${args.searchText || ''}, root=${args.rootPath || '/sitecore/content'}, lang=${args.language || 'en'})`
        );
        const filters: any = {};
        if (args.pathContains) filters.pathContains = args.pathContains;
        if (args.pathStartsWith) filters.pathStartsWith = args.pathStartsWith;
        if (args.nameContains) filters.nameContains = args.nameContains;
        if (args.templateIn) filters.templateIn = args.templateIn;
        if (args.hasChildrenFilter !== undefined)
          filters.hasChildrenFilter = args.hasChildrenFilter;
        if (args.hasLayoutFilter !== undefined) filters.hasLayoutFilter = args.hasLayoutFilter;

        const result = await sitecoreService.searchItemsPaginated(
          args.searchText as string | undefined,
          args.rootPath as string | undefined,
          args.templateName as string | undefined,
          args.language as string,
          args.database as string,
          args.maxItems as number,
          args.index as string | undefined,
          undefined, // fieldsEqual - not yet implemented in UI
          undefined, // facetOn - not yet implemented in UI
          args.latestVersion as boolean | undefined,
          args.after as string | undefined,
          Object.keys(filters).length > 0 ? filters : undefined,
          args.orderBy as
            | Array<{ field: 'name' | 'displayName' | 'path'; direction: 'ASC' | 'DESC' }>
            | undefined
        );
        const count = result.items.length;
        progress(
          `Completed: ${count} item(s), hasNextPage=${Boolean(result.pageInfo?.hasNextPage)}`
        );
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_get_field_value': {
        const progress = (m: string) => console.error(`[sitecore_get_field_value] ${m}`);
        progress(
          `Starting (path=${args.path}, field=${args.fieldName}, lang=${args.language || 'en'})`
        );
        const result = await sitecoreService.getFieldValue(
          args.path as string,
          args.fieldName as string,
          args.language as string,
          args.database as string,
          args.version as number | undefined
        );
        progress(`Completed`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_get_template': {
        const progress = (m: string) => console.error(`[sitecore_get_template] ${m}`);
        progress(`Starting (path=${args.templatePath}, db=${args.database || 'master'})`);
        const result = await sitecoreService.getTemplate(
          args.templatePath as string,
          args.database as string
        );
        progress(`Completed`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_get_item_fields': {
        const progress = (m: string) => console.error(`[sitecore_get_item_fields] ${m}`);
        progress(`Starting (path=${args.path}, lang=${args.language || 'en'})`);
        const result = await sitecoreService.getItemFieldsFromTemplate(
          args.path as string,
          args.language as string | undefined,
          args.version as number | undefined
        );
        progress(`Completed: ${result?.length || 0} field(s)`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(
                {
                  path: args.path,
                  totalFields: result.length,
                  fields: result,
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case 'sitecore_get_layout': {
        const progress = (m: string) => console.error(`[sitecore_get_layout] ${m}`);
        progress(
          `Starting (site=${args.site}, route=${args.routePath}, lang=${args.language || 'en'})`
        );
        const result = await sitecoreService.getLayout(
          args.site as string,
          args.routePath as string,
          (args.language as string) || 'en'
        );
        progress(`Completed`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_get_sites': {
        const progress = (m: string) => console.error(`[sitecore_get_sites] ${m}`);
        progress(`Starting (name=${args.name || ''})`);
        const result = await sitecoreService.getSites(
          args.name as string | undefined,
          args.current as boolean | undefined,
          args.includeSystemSites as boolean | undefined
        );
        progress(`Completed: ${result?.length || 0} site(s)`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_get_templates': {
        const progress = (m: string) => console.error(`[sitecore_get_templates] ${m}`);
        progress(`Starting (path=${args.path || '/sitecore/templates'})`);
        const result = await sitecoreService.getTemplates(args.path as string | undefined);
        progress(`Completed: ${result?.length || 0} template(s)`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_create_item': {
        const progress = (m: string) => console.error(`[sitecore_create_item] ${m}`);
        progress(
          `Starting (name=${args.name}, parent=${args.parent}, template=${args.template}, lang=${args.language})`
        );
        const result = await sitecoreService.createItem(
          args.name as string,
          args.template as string,
          args.parent as string,
          args.language as string
        );
        progress(`Completed`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_update_item': {
        const progress = (m: string) => console.error(`[sitecore_update_item] ${m}`);
        progress(
          `Starting (path=${args.path}, lang=${args.language}, version=${args.version || ''}, name=${args.name || ''})`
        );
        const result = await sitecoreService.updateItem(
          args.path as string,
          args.language as string,
          args.version as number | undefined,
          args.name as string | undefined
        );
        progress(`Completed`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_delete_item': {
        const progress = (m: string) => console.error(`[sitecore_delete_item] ${m}`);
        progress(`Starting (path=${args.path}, permanent=${args.deletePermanently === true})`);
        const result = await sitecoreService.deleteItem(
          args.path as string,
          args.deletePermanently as boolean
        );
        progress(`Completed: success=${Boolean(result)}`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify({ success: result, path: args.path }, null, 2),
            },
          ],
        };
      }

      case 'sitecore_scan_schema': {
        const progress = (m: string) => console.error(`[sitecore_scan_schema] ${m}`);
        progress(`Starting schema analysis...`);
        const analysis = await sitecoreService.analyzeSchema();
        progress(
          `Completed: ${analysis?.operations?.queries?.length || 0} queries, ${analysis?.operations?.mutations?.length || 0} mutations`
        );

        // Save to file if requested
        if (args.saveToFile !== false) {
          const fs = await import('fs/promises');
          const path = await import('path');
          const outputPath = path.join(process.cwd(), 'schema-analysis.json');
          await fs.writeFile(outputPath, JSON.stringify(analysis, null, 2));
          analysis._savedTo = outputPath;
        }

        // Create readable summary
        const summary = {
          timestamp: analysis.timestamp,
          endpoint: analysis.endpoint,
          summary: {
            queries: analysis.operations.queries.length,
            mutations: analysis.operations.mutations.length,
            subscriptions: analysis.operations.subscriptions?.length || 0,
            customTypes: analysis.customTypes.length,
            templateTypes: analysis.templateTypes.length,
            inputTypes: analysis.inputTypes.length,
          },
          availableQueries: analysis.operations.queries.map((q: any) => ({
            name: q.name,
            description: q.description,
            requiredArgs: q.arguments.filter((a: any) => a.required).map((a: any) => a.name),
            optionalArgs: q.arguments.filter((a: any) => !a.required).map((a: any) => a.name),
          })),
          availableMutations: analysis.operations.mutations.map((m: any) => ({
            name: m.name,
            description: m.description,
          })),
          sampleTemplates: analysis.templateTypes.slice(0, 10),
          fullAnalysis:
            args.saveToFile !== false ? analysis._savedTo : 'Set saveToFile:true to save',
        };

        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(summary, null, 2),
            },
          ],
        };
      }

      case 'sitecore_command': {
        const progress = (m: string) => console.error(`[sitecore_command] ${m}`);
        progress(`Starting (command=${(args.command as string)?.substring(0, 40)}...)`);
        const result = await sitecoreService.parseSitecoreCommand(args.command as string);
        progress(`Completed (action=${result.action})`);

        // Format response based on action
        let response = '';

        switch (result.action) {
          case 'help':
            response =
              '# 🔧 Sitecore Commands\n\n' +
              '## Available Commands\n\n' +
              result.examples.map((ex: string) => `- \`${ex}\``).join('\n') +
              '\n\n💡 **Tip:** Type `/sitecore examples` for categorized examples!';
            break;

          case 'examples':
            response = '# 📚 Sitecore Command Examples\n\n';
            for (const cat of result.categories) {
              response += `## ${cat.category}\n\n`;
              for (const ex of cat.examples) {
                response += `### \`${ex.command}\`\n${ex.description}\n\n`;
              }
            }
            break;

          case 'schema_scan':
            response =
              `# 🔍 Schema Scan Complete\n\n` +
              `**Endpoint:** ${result.result.endpoint}\n` +
              `**Timestamp:** ${result.result.timestamp}\n\n` +
              `## Statistics\n` +
              `- **Queries:** ${result.result.operations.queries.length}\n` +
              `- **Mutations:** ${result.result.operations.mutations.length}\n` +
              `- **Subscriptions:** ${result.result.operations.subscriptions?.length || 0}\n` +
              `- **Template Types:** ${result.result.templateTypes.length}\n` +
              `- **Custom Types:** ${result.result.customTypes.length}\n\n` +
              `## Top Query Operations\n` +
              result.result.operations.queries
                .slice(0, 8)
                .map((q: any) => `- **${q.name}**: ${q.description || 'No description'}`)
                .join('\n');
            break;

          case 'list_templates':
            response =
              `# 📋 Sitecore Templates\n\n` +
              `**Total Templates:** ${result.result.count}\n\n` +
              (result.result.note ? `> ${result.result.note}\n\n` : '') +
              result.result.templates
                .map((t: any) => `- **${t.name}**\n  - Path: \`${t.path}\`\n  - ID: \`${t.id}\``)
                .join('\n');
            break;

          case 'list_sites':
            if (result.error) {
              response =
                `# ⚠️ Sites Information\n\n${result.error}\n\n` +
                `This is normal - not all Sitecore instances expose site information via GraphQL.`;
            } else {
              response =
                `# 🌐 Sitecore Sites\n\n` +
                `**Total Sites:** ${result.result.count}\n\n` +
                result.result.sites
                  .map(
                    (s: any) =>
                      `- **${s.name}**\n  - Host: ${s.hostName}\n  - Database: ${s.database}\n  - Language: ${s.language}`
                  )
                  .join('\n');
            }
            break;

          case 'get_item': {
            const item = result.result;
            response =
              `# 📄 Item: ${item.name}\n\n` +
              `**Display Name:** ${item.displayName}\n` +
              `**Path:** \`${item.path}\`\n` +
              `**ID:** \`${item.id}\`\n` +
              `**Template:** ${item.templateName} (\`${item.templateId}\`)\n` +
              `**Language:** ${item.language}\n` +
              `**Version:** ${item.version}\n` +
              `**Has Children:** ${item.hasChildren ? 'Yes' : 'No'}\n` +
              (result.note ? `\n> ${result.note}` : '');
            break;
          }

          case 'search':
            response =
              `# 🔎 Search Results\n\n` +
              (result.note ? `${result.note}\n\n` : '') +
              `**Found:** ${result.result.length} items\n\n`;
            if (result.result.length > 0) {
              response += result.result
                .slice(0, 10)
                .map(
                  (item: any) =>
                    `- **${item.name}**\n  - Path: \`${item.path}\`\n  - Template: ${item.templateName}`
                )
                .join('\n');
              if (result.result.length > 10) {
                response += `\n\n...and ${result.result.length - 10} more items.`;
              }
            }
            break;

          case 'get_children':
            response = `# 👶 Child Items\n\n` + `**Found:** ${result.result.length} children\n\n`;
            if (result.result.length > 0) {
              response += result.result
                .map(
                  (child: any) =>
                    `- **${child.name}**\n  - Path: \`${child.path}\`\n  - Template: ${child.templateName}\n  - Has Children: ${child.hasChildren ? 'Yes' : 'No'}`
                )
                .join('\n');
            }
            break;

          case 'get_field':
            response =
              `# 🏷️ Field Value\n\n` +
              `**Field:** ${result.result.fieldName}\n` +
              `**Type:** ${result.result.type}\n` +
              `**Value:** \`${result.result.value}\``;
            break;

          case 'create_item':
            if (result.error) {
              response =
                `# ❌ Item Creation Failed\n\n` +
                `**Error:** ${result.error}\n\n` +
                `> ${result.note}`;
            } else {
              response =
                `# ✅ Item Created Successfully\n\n` +
                `**Name:** ${result.result.name}\n` +
                `**Path:** \`${result.result.path}\`\n` +
                `**ID:** \`${result.result.id}\`\n\n` +
                `> ${result.note}`;
            }
            break;

          case 'update_item':
            if (result.error) {
              response =
                `# ❌ Item Update Failed\n\n` +
                `**Error:** ${result.error}\n\n` +
                `> ${result.note}`;
            } else {
              response =
                `# ✅ Item Updated Successfully\n\n` +
                `**Name:** ${result.result.name}\n` +
                `**Path:** \`${result.result.path}\`\n\n` +
                `> ${result.note}`;
            }
            break;

          case 'delete_item':
            if (result.error) {
              response =
                `# ❌ Item Deletion Failed\n\n` +
                `**Error:** ${result.error}\n\n` +
                `> ${result.note}`;
            } else {
              response =
                `# ✅ Item Deletion ${result.result.success ? 'Successful' : 'Failed'}\n\n` +
                `**Path:** \`${result.result.path}\`\n\n` +
                `> ${result.note}`;
            }
            break;

          case 'unknown':
            response =
              `# ❓ Unknown Command\n\n` +
              `${result.message}\n\n` +
              `**You typed:** \`${result.input}\`\n\n` +
              `## Suggestions\n` +
              result.suggestions.map((s: string) => `- ${s}`).join('\n');
            break;

          default:
            response = '# Response\n\n```json\n' + JSON.stringify(result.result, null, 2) + '\n```';
        }

        return {
          content: [
            {
              type: 'text',
              text: response,
            },
          ],
        };
      }

      case 'sitecore_get_parent': {
        const progress = (m: string) => console.error(`[sitecore_get_parent] ${m}`);
        progress(`Starting (path=${args.path}, lang=${args.language || 'en'})`);
        const result = await sitecoreService.getParent(
          args.path as string,
          args.language as string,
          args.version as number | undefined
        );
        progress(`Completed: ${result ? `parent=${result.name}` : 'no parent (root)'}`);
        return {
          content: [
            {
              type: 'text',
              text: result ? JSON.stringify(result, null, 2) : 'No parent found (item is at root)',
            },
          ],
        };
      }

      case 'sitecore_get_ancestors': {
        const progress = (m: string) => console.error(`[sitecore_get_ancestors] ${m}`);
        progress(`Starting (path=${args.path}, lang=${args.language || 'en'})`);
        const result = await sitecoreService.getAncestors(
          args.path as string,
          args.language as string,
          args.version as number | undefined
        );
        progress(`Completed: ${result.length} ancestor(s)`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(
                {
                  count: result.length,
                  ancestors: result,
                  breadcrumb: result
                    .map((a) => a.name)
                    .reverse()
                    .join(' > '),
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case 'sitecore_get_item_versions': {
        const progress = (m: string) => console.error(`[sitecore_get_item_versions] ${m}`);
        progress(`Starting (path=${args.path}, lang=${args.language || 'en'})`);
        const result = await sitecoreService.getItemVersions(
          args.path as string,
          args.language as string
        );
        progress(`Completed: ${result.length} version(s)`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(
                {
                  totalVersions: result.length,
                  versions: result,
                  latestVersion: result.length > 0 ? result[result.length - 1].version : null,
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case 'sitecore_get_item_with_statistics': {
        const progress = (m: string) => console.error(`[sitecore_get_item_with_statistics] ${m}`);
        progress(`Starting (path=${args.path}, lang=${args.language || 'en'})`);
        const result = await sitecoreService.getItemWithStatistics(
          args.path as string,
          args.language as string,
          args.version as number | undefined
        );
        progress(`Completed`);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      case 'sitecore_discover_item_dependencies': {
        // Create progress callback to report status
        const progressCallback = (step: number, message: string) => {
          // Log to stderr so it appears in MCP client
          console.error(`[Discovery ${step}/7] ${message}`);
        };

        const result = await sitecoreService.discoverItemDependencies(
          args.path as string,
          args.language as string,
          Boolean(args.includeRenderings), // default false unless explicitly true
          Boolean(args.includeResolvers), // default false unless explicitly true
          progressCallback
        );
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2),
            },
          ],
        };
      }

      default:
        throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
    }
  } catch (error) {
    if (error instanceof McpError) {
      throw error;
    }
    throw new McpError(
      ErrorCode.InternalError,
      `Error executing tool ${name}: ${error instanceof Error ? error.message : String(error)}`
    );
  }
});

// Start the server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Sitecore MCP Server running on stdio');
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
