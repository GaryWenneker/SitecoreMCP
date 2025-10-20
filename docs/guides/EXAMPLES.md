# Sitecore MCP - Usage Examples

These examples can be used in Claude Desktop (or any MCP client) after configuring the Sitecore MCP server.

## Basic Item Operations

### Get item by path
```
Get the Home item via path /sitecore/content/Home
```

### Get item by ID
```
Get the item with ID {110D559F-DEA5-42EA-9C1C-8A5DF7E70EF9}
```

### Get item in another language
```
Get /sitecore/content/Home in Dutch
```

## Children and Hierarchy

### Get direct children
```
Show all direct children of /sitecore/content/Home
```

### Get all items recursively
```
Get all items recursively under /sitecore/content/Home
```

### Children with filter
```
Show all children of /sitecore/content/Home with template 'Sample Item'
```

## Queries

### Simple query
```
Execute this query: /sitecore/content/Home//*
```

### Query by template
```
Find all items with template 'Article': /sitecore/content/Home//*[@@templatename='Article']
```

### Query by field value
```
Find items where Title equals 'Contact': /sitecore/content/Home//*[@Title='Contact']
```

### Query with wildcards
```
Find items with 'about' in the name: /sitecore/content//*[@@name='*about*']
```

## Searching

### Search by name
```
Search for items with 'contact' in the name under /sitecore/content
```

### Search with template filter
```
Search for items with 'home' in the name that have the 'Folder' template
```

### Search in specific folder
```
Search for 'product' items under /sitecore/content/Home/Products
```

## Field Operations

### Get single field value
```
What is the value of the Title field of /sitecore/content/Home?
```

### Get all fields of an item
```
Show all field values of /sitecore/content/Home
```

### Get field value in another language
```
Get the Title field of /sitecore/content/Home in Dutch
```

## Template Information

### Get template details
```
Show the template definition of /sitecore/templates/Sample/Sample Item
```

### Get template fields
```
What fields does the 'Article' template have?
```

### Get base templates
```
What are the base templates of /sitecore/templates/Sample/Sample Item?
```

## Advanced Examples

### Combination: Search and get fields
```
Find all items with 'contact' in the name and show their Title and Description fields
```

### Analysis: Template usage
```
How many items use the 'Sample Item' template under /sitecore/content?
```

### Structure overview
```
Give me an overview of the content structure under /sitecore/content/Home
```

### Items without field value
```
Find all Article items where the Description field is empty
```

### Recently modified items
```
Which items under /sitecore/content were recently modified? (use Updated field)
```

## Multi-step Analyses

### Content audit
```
1. Find all items under /sitecore/content/Home
2. Group them by template
3. Show the counts per template type
```

### Field compliance check
```
1. Find all Article items
2. Check which items have an empty Title
3. Provide a list of items that need to be updated
```

### Hierarchy report
```
1. Get /sitecore/content
2. For each child item, get the children
3. Create a tree structure overview
```

## Database and Language Options

### Use web database
```
Get /sitecore/content/Home from the web database
```

### Use core database
```
Show items from /sitecore/content in the core database
```

### Multilingual content
```
Compare the Title field of /sitecore/content/Home in English and Dutch
```

## Tips for Effective Use

1. **Start broad, zoom in**: Begin with an overview (children) and then zoom in on specific items

2. **Use queries for complex filters**: For multiple criteria, use Sitecore queries

3. **Combine tools**: Use search to find items, then get_item for details

4. **Template-first approach**: First get template info to see which fields are available

5. **Check database and language**: Don't forget to specify the correct database (master/web) and language

## Common Patterns

### Content Inventory
```
1. Search for all items in a section
2. Group by template
3. Count quantities
```

### Quality Check
```
1. Get items
2. Check required fields
3. Report missing values
```

### Structure Analysis
```
1. Get hierarchy
2. Analyze depth
3. Find outliers
```

## Debugging

If a query doesn't work:
1. Check the path (case-sensitive!)
2. Verify the database (master vs web)
3. Check the language code
4. Test the query in Sitecore PowerShell ISE first
5. Look in Sitecore logs: /sitecore/admin/showlog.aspx
