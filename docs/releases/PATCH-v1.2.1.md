# Patch v1.2.1 - Schema Fix

**Release Date**: October 16, 2025  
**Type**: Bug Fix (Patch)  
**Previous Version**: 1.2.0  
**Author**: Gary Wenneker

## 🐛 Bug Fix

### Issue
`sitecore_get_children` tool returned GraphQL error:
```
Error: Cannot query field "results" on type "Item"
```

### Root Cause
The `/items/master` schema has a **different structure** than the old `/edge` schema:
- **Old /edge**: `children { results { ... } }` (ItemSearchResults type)
- **New /items/master**: `children(first: 100) { ... }` (direct [Item] array)

### Solution
Fixed `getChildren()` method in `src/sitecore-service.ts`:
- ✅ Removed `results` field access
- ✅ Added `first: 100` pagination argument
- ✅ Changed to direct array access: `children` instead of `children.results`

## 📝 Changes

### Modified Files
1. **src/sitecore-service.ts** - Fixed children query structure
2. **src/index.ts** - Version bumped to 1.2.1
3. **package.json** - Version bumped to 1.2.1

### Test Results
```powershell
✅ GraphQL Query: SUCCESS
✅ TypeScript Build: SUCCESS
✅ Children returned: 3 items
```

## 📚 Documentation

New documentation:
- **SCHEMA-FIX-CHILDREN.md** - Complete analysis of the schema difference

## 🚀 How to Update

```bash
cd c:\gary\Sitecore\SitecoreMCP
npm run build
```

Then restart your MCP client (Claude Desktop, VS Code, etc.).

## ✅ Impact

### Fixed
- ✅ `sitecore_get_children` now works correctly

### Unaffected (Still Working)
- ✅ `sitecore_get_item`
- ✅ `sitecore_search` (uses `search().results`, which is correct)
- ✅ `sitecore_query` (uses `search().results`)
- ✅ `sitecore_get_field_value`
- ✅ `sitecore_get_template`
- ✅ `sitecore_command` (natural language interface)
- ✅ `/sitecore` slash command menu

## 🔍 Technical Details

See [SCHEMA-FIX-CHILDREN.md](SCHEMA-FIX-CHILDREN.md) for:
- Complete schema comparison
- Code changes (before/after)
- Testing procedures
- Lessons learned

---

**Status**: ✅ READY FOR USE  
**Build**: ✅ SUCCESS  
**Tests**: ✅ PASS
