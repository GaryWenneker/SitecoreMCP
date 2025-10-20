# Test GraphQL Search Query for /sitecore/api/graph/items/master

## What we know from errors:
- ❌ ContentSearchResults does NOT have `.total` field
- ❌ ContentSearchResult does NOT have `.displayName` field
- ❌ ContentSearchResult does NOT have `.template` field (has `.templateName` instead)
- ❌ ContentSearchResult does NOT have `.hasChildren` field

## Likely correct fields (based on error suggestions):
- ✅ ContentSearchResult has `.templateName` (string)
- ✅ ContentSearchResult likely has `.name`, `.id`, `.path` (standard)

## Test query to find correct structure:

```graphql
{
  search(keyword: "Home", language: "en", first: 1) {
    results {
      items {
        id
        name
        path
        templateName
        url
        language {
          name
        }
      }
    }
  }
}
```

## Expected structure based on /items/master endpoint:

```typescript
interface ContentSearchResults {
  results: {
    items: ContentSearchResult[];
    pageInfo?: {
      hasNextPage: boolean;
      endCursor: string;
    };
    totalCount?: number;
  };
  facets?: ContentSearchFacet[];
}

interface ContentSearchResult {
  id: string;
  name: string;
  path: string;
  templateName: string;  // NOT template { id, name }
  uri?: string;          // NOT url! (uri, not url)
  language: string;      // SCALAR String! (not object with .name)
  // NO: displayName, template, hasChildren, fields
}
```

## Fix needed in sitecore-service.ts:

Change from Item-based fields to ContentSearchResult fields:
- Remove: `displayName`, `template { id, name }`, `hasChildren`, `fields`
- Use: `id`, `name`, `path`, `templateName`, `uri`, `language` (String!)
- ⚠️ `uri` NOT `url`
- ⚠️ `language` is String, NOT `language { name }`
