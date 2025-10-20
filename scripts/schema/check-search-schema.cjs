const fs = require('fs');

const schema = JSON.parse(fs.readFileSync('.github/introspectionSchema.json', 'utf8'));

// Check ContentSearchResult
const searchResult = schema._typeMap.ContentSearchResult;
console.log('ContentSearchResult type:', typeof searchResult);
console.log('Is array?', Array.isArray(searchResult));

if (Array.isArray(searchResult)) {
  console.log('\nContentSearchResult fields:');
  searchResult.forEach((field, index) => {
    console.log(`  [${index}] ${JSON.stringify(field)}`);
  });
}

console.log('\n---\n');

// Check ContentSearchResults
const searchResults = schema._typeMap.ContentSearchResults;
console.log('ContentSearchResults type:', typeof searchResults);
console.log('Is array?', Array.isArray(searchResults));

if (Array.isArray(searchResults)) {
  console.log('\nContentSearchResults fields:');
  searchResults.forEach((field, index) => {
    console.log(`  [${index}] ${JSON.stringify(field)}`);
  });
}
