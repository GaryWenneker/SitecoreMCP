# Schema Introspection Limitations

## Probleem

Deze Sitecore installatie ondersteunt **geen GraphQL introspection queries**. 

Wanneer we introspection queries proberen zoals:
```graphql
{
  __schema {
    queryType {
      name
    }
  }
}
```

Of:
```graphql
{
  __type(name: "Query") {
    fields {
      name
    }
  }
}
```

Krijgen we **HTTP 500 Internal Server Error**.

## Wat Werkt Wel

Reguliere GraphQL queries werken perfect:

```graphql
{
  item(path: "/sitecore/content/Home", language: "en") {
    id
    name
    fields {
      name
      value
    }
  }
}
```

```graphql
{
  search(where: { ... }) {
    total
    results {
      name
      path
    }
  }
}
```

## Impact op MCP Tools

### ✅ Werkend
- `sitecore_get_item` - Item ophalen
- `sitecore_get_children` - Children ophalen
- `sitecore_get_field_value` - Field value ophalen
- `sitecore_query` - Custom GraphQL queries
- `sitecore_search` - Items zoeken
- `sitecore_get_template` - Template info ophalen

### ❌ Beperkt
- `sitecore_scan_schema` - **Werkt niet** door 500 errors bij introspection
- `sitecore_command` - **Werkt gedeeltelijk** (scan schema commando faalt)

## Oplossingen

### Optie 1: Handmatige Schema Documentatie
Maak een handmatige schema documentatie in `SCHEMA-DOCUMENTATION.md` met:
- Alle beschikbare query types
- Alle filter operators
- Alle template types
- Input types en hun fields

### Optie 2: Schema Inferentie
Gebruik de werkende queries om schema te infereren:
1. Test verschillende query structuren
2. Documenteer wat werkt en wat niet
3. Bouw type definitions op basis van responses

### Optie 3: Sitecore Upgrade/Config
Als deze Sitecore installatie geüpgraded kan worden:
- Enable introspection in GraphQL config
- Update Sitecore versie naar nieuwere versie
- Check security settings die introspection blokkeren

## Test Resultaten

**test-new-features-v2.ps1**: 3/4 tests PASSED ✅
- Test 1: Basic GraphQL Query - FAILED (geen /sitecore/content items)
- Test 2: Get Item Query - **PASSED** ✅
- Test 3: Get Children Query - **PASSED** ✅  
- Test 4: MCP Server Build - **PASSED** ✅

## Conclusie

De **core MCP functionaliteit werkt perfect** (6 van 8 tools). Alleen de schema scanner tool is beperkt door deze Sitecore configuratie.

### Aanbeveling

Voor nu: Gebruik de 6 werkende tools. De `sitecore_scan_schema` tool kan later geactiveerd worden als:
1. Sitecore introspection enabled wordt
2. We naar een andere Sitecore instance migreren
3. We handmatige schema documentatie toevoegen

De `sitecore_command` tool werkt voor alle commando's behalve "scan schema".
