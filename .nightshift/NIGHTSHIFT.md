# NIGHTSHIFT.md — Autonomous Nightly Work Pipeline

## Overview
Runs at 3:00 AM PST while Ian sleeps. Deploys Codex agents to active projects for UX fixes and performance tuning.

## Target Projects

| Time | Project | Path | Audit File | Status |
|------|---------|------|------------|--------|
| 3:00 AM | CheerCenter | ~/Projects/CheerCenter | CheerCenter-UX-Friction-Audit.md | Active |
| 3:15 AM | ScoreBin | ~/Projects/ScoreBin | ScoreBin-UX-Friction-Audit.md | Active |
| 3:30 AM | CheerCOM | ~/Projects/CheerCOM | CheerCOM-UX-Friction-Audit.md | Backburner |
| 3:45 AM | CheerStatsSolo | ~/Projects/CheerStatsSolo | CheerStatsSolo-UX-Friction-Audit.md | Backburner |
| 4:00 AM | CheerMotionMetronome | ~/Projects/cheer-motion-metronome | CheerMotionMetronome-UX-Friction-Audit.md | Backburner |
| 4:15 AM | UniversalInbox | ~/Projects/universal-inbox | UniversalInbox-UX-Friction-Audit.md | Paused |

## Agent Mission

For each project, Codex should:

### 1. UX Friction Fixes (Priority Order)
1. Read the project's `*-UX-Friction-Audit.md` from vault
2. Work through **P0 items first**, then P1
3. One commit per fix
4. Create PR if changes are substantial

### 2. Performance Tune-ups
1. Run build and identify warnings
2. Check for:
   - Unnecessary re-renders (SwiftUI)
   - Heavy computed properties
   - Missing lazy loading
   - Memory leaks (retain cycles)
3. Profile if simulator available
4. Fix low-hanging fruit

### 3. Code Quality
1. Remove dead code
2. Fix linter warnings
3. Add missing documentation to public APIs
4. Ensure consistent naming

## Constraints
- **Max 3 PRs per project per night** — Don't overwhelm
- **No breaking changes** — Only additive or cosmetic fixes
- **Commit message format:** `[nightshift] <type>: <description>`
- **Skip if build fails** — Don't work on broken projects

## Execution Model

Nightshift jobs run as **isolated OpenClaw agent sessions** (no direct CLI access — no git, no codex, no cd). The agent reads audit files from the vault, then delegates actual coding work to a `coding-session` subagent via the `agentToAgent` tool. The subagent has full host access (git, codex, etc.) and performs branching, code changes, and pushes.

**Do NOT instruct agents to run shell commands directly.** Always delegate via `coding-session`.

## Delivery
Results summarized and sent to main session on completion.

## Audit File Locations (Vault)
```
/Users/ianrichardson/Library/Mobile Documents/iCloud~md~obsidian/Documents/fsu/10-Projects/
├── CheerCenter-UX-Friction-Audit.md
├── ScoreBin-UX-Friction-Audit.md
└── CheerCOM-UX-Friction-Audit.md
```
