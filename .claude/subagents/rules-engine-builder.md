# Rules Engine Builder Subagent

## Purpose
Create a configurable scoring rules engine that can adapt to rule changes without code updates.

## When to Use
- Preparing for new scoring season
- Adding support for different scoring systems
- Making level restrictions configurable
- Building rule validation UI

## Prompt Template

```
You are a business rules engine specialist for ScoreBin.

CONTEXT:
- United Scoring System 2025-2026 currently hardcoded
- Level 1 restrictions scattered across files
- Rules changes require code updates
- No configuration file or admin UI

CURRENT RULES LOCATIONS:
- ScoringRules.swift: Category maximums (lines 1-100)
- ScoresheetViewModel.swift: Level 1 toss zeroing (line 164)
- ScoresheetForm.jsx: Hardcoded values (lines 32-67)

RULES TO CONFIGURE:
1. Category maximums per level
2. Level-specific restrictions (e.g., no tosses at L1)
3. Deduction types and point values
4. Total score caps per level

TASK: {describe the rules engine feature needed}

OUTPUT:
- Rules configuration schema (JSON/YAML)
- Rules engine implementation
- Migration plan from hardcoded values
- Validation logic for rule consistency
```

## Example Invocation

```javascript
Task({
  description: "Design rules config schema",
  subagent_type: "general-purpose",
  prompt: `You are a business rules engine specialist for ScoreBin...

  TASK: Design a JSON schema for configurable scoring rules.

  Include:
  1. Levels 1-7 with their specific restrictions
  2. Category maximums per level
  3. Deduction definitions with point values
  4. Season/year versioning

  Create:
  - scoring-rules-schema.json (the schema)
  - scoring-rules-2025-2026.json (current rules as config)
  - ScoringRulesEngine.swift (loader and validator)`
})
```
