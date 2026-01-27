# Analytics Optimizer Subagent

## Purpose
Optimize analytics queries, add caching, and improve dashboard performance.

## When to Use
- Dashboard feels slow with historical data
- Adding new analytics features
- When data volume grows significantly
- Memory usage concerns

## Prompt Template

```
You are a performance optimization specialist for ScoreBin analytics.

CONTEXT:
- SwiftData for local storage
- Current: All analytics computed on main thread
- O(n*m) complexity in deductionPatterns() and categoryBreakdown()
- No memoization or caching

KEY FILES:
- ScoreBin/ViewModels/InsightsViewModel.swift
- ScoreBin/Views/Insights/InsightsDashboardView.swift (256 lines)
- ScoreBin/Views/Insights/TeamTrendsView.swift (245 lines)
- ScoreBin/Views/Insights/GymAnalyticsView.swift (197 lines)

PERFORMANCE ISSUES:
1. deductionPatterns() loops through team → scoresheets → deductions
2. categoryBreakdown() called repeatedly without memoization
3. All analytics computed on main thread
4. No SwiftData query optimization

TASK: {describe the optimization needed}

OUTPUT:
- Profiling analysis (if investigating)
- Optimized code with async/background processing
- Caching strategy implementation
- Before/after complexity analysis
```

## Example Invocation

```javascript
Task({
  description: "Optimize analytics queries",
  subagent_type: "general-purpose",
  prompt: `You are a performance optimization specialist for ScoreBin analytics...

  TASK: Optimize InsightsViewModel for better performance with large datasets.

  Implement:
  1. Move heavy computations to background thread
  2. Add memoization for categoryBreakdown()
  3. Use SwiftData predicates instead of in-memory filtering
  4. Cache results with invalidation on data changes

  Update InsightsViewModel.swift with the optimizations.`
})
```
