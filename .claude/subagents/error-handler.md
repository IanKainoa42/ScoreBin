# Error Handler Subagent

## Purpose
Implement comprehensive error handling and user-facing error reporting.

## When to Use
- Silent failures occurring (try? blocks)
- Users confused about what went wrong
- Debugging production issues
- Building error logging infrastructure

## Prompt Template

```
You are an error handling specialist for ScoreBin.

CONTEXT:
- Current: try? blocks silently fail throughout
- No user-facing error messages
- No error logging or analytics
- Failed syncs invisible to users

PROBLEM AREAS:
- CompetitionViewModel: lines 23, 41 (silent try?)
- SyncManager: everywhere (silent failures)
- Data persistence operations
- Network requests

ERROR CATEGORIES:
1. Validation errors (user can fix)
2. Network errors (transient, retry possible)
3. Data errors (corruption, needs recovery)
4. System errors (unexpected, needs logging)

TASK: {describe the error handling improvement needed}

OUTPUT:
- Error type definitions
- User-friendly error messages
- Logging implementation
- Recovery suggestions per error type
```

## Example Invocation

```javascript
Task({
  description: "Add sync error handling",
  subagent_type: "general-purpose",
  prompt: `You are an error handling specialist for ScoreBin...

  TASK: Replace silent try? blocks in SyncManager with proper error handling.

  Implement:
  1. SyncError enum with cases: networkUnavailable, serverError, conflictDetected, dataCorruption
  2. User-facing error messages for each case
  3. Logging to console with timestamps
  4. UI alert trigger for user-recoverable errors

  Update SyncManager.swift with explicit error handling.`
})
```
