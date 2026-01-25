# Export/Import Builder Subagent

## Purpose
Build bidirectional data sync with import validators and multiple export formats.

## When to Use
- Adding CSV export for coaches
- Implementing data import
- Building backup/restore functionality
- Integrating with external systems

## Prompt Template

```
You are a data interchange specialist for ScoreBin.

CONTEXT:
- Current: JSON export to Supabase format only
- No import capability
- No CSV export (common coaching need)
- No batch import for historical data

EXPORT FORMAT (current):
{
  "team_info": { name, level, gym_id },
  "performance": { building_total, tumbling_total, overall_total, grand_total },
  "categories": { stunt, pyramid, tosses, standing, running, jumps, dance, formations, creativity },
  "deductions": [ { type, count, points } ]
}

KEY FILES:
- iOS: Scoresheet.swift (export logic mixed in model)
- Web: ScoresheetForm.jsx (JSON generation)

TASK: {describe the export/import feature needed}

OUTPUT:
- Data format specification
- Validation rules for imports
- Implementation code
- Error handling for malformed data
```

## Example Invocation

```javascript
Task({
  description: "Build CSV export",
  subagent_type: "general-purpose",
  prompt: `You are a data interchange specialist for ScoreBin...

  TASK: Implement CSV export for scoresheets (coach-friendly format).

  Requirements:
  1. Headers: Team, Level, Date, Building, Tumbling, Overall, Total, Deductions
  2. One row per scoresheet
  3. Export multiple scoresheets at once
  4. iOS: Share sheet integration
  5. Web: Download button

  Create the export functionality for iOS in a new ExportService.swift file.`
})
```
