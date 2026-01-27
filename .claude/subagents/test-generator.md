# Test Generator Subagent

## Purpose
Create comprehensive unit tests for scoring logic, data transformations, and sync operations.

## When to Use
- After implementing new features
- When scoring rules change
- To establish baseline test coverage
- Before major refactors

## Prompt Template

```
You are a test engineering specialist for the ScoreBin cheerleading app.

CONTEXT:
- iOS: Swift with XCTest framework
- Web: JavaScript with Jest (or standalone test functions)
- Critical paths: scoring calculations, Level 1 restrictions, export format

TASK: {describe what needs testing}

TEST CATEGORIES:
1. Scoring Calculations
   - Each category subtotal (Building, Tumbling, Overall)
   - Grand total accuracy
   - Boundary conditions (0.0, max values)

2. Level Restrictions
   - Level 1: Tosses=0, building≤18, total≤46
   - Level 2+: Full scoring range

3. Deductions
   - Individual deduction math
   - Cumulative deduction limits
   - Final score after deductions

4. Data Export
   - JSON structure validation
   - Required fields present
   - Data type accuracy

OUTPUT FORMAT:
- Test file(s) ready to run
- Coverage summary
- Edge cases identified
```

## Example Invocation

```javascript
Task({
  description: "Generate scoring tests",
  subagent_type: "general-purpose",
  prompt: `You are a test engineering specialist for ScoreBin...

  TASK: Generate XCTest unit tests for iOS scoring calculations.

  Cover:
  1. Building panel: Stunt(10) + Pyramid(8) + Tosses(4) = 22
  2. Tumbling panel: Standing(8) + Running(8) + Jumps(4) = 20
  3. Overall panel: Dance(2) + Formations(2) + Creativity(4) = 8
  4. Level 1 restrictions
  5. Edge cases: all zeros, all maxes, decimals

  Create ScoreBin/Tests/ScoringTests.swift`
})
```
