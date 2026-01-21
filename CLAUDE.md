# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ScoreBin is a cheerleading scoresheet entry application implementing the **United Scoring System 2025-2026**. It provides an interactive form for judges to enter scores that auto-calculates totals and exports data for database storage.

## Files

- `ScoresheetForm.jsx` - React component (ES module format, requires bundler)
- `scoresheet_form.html` - Standalone HTML version with inline React via CDN (no build required)

## Running the Application

**HTML version (no build):**
```bash
open scoresheet_form.html
```
Opens directly in browser using CDN-loaded React 18, ReactDOM, Babel, and Tailwind CSS.

**JSX version:**
Requires a React project setup with bundler (Vite, CRA, etc.) to use the exported component.

## Scoring System Architecture

### Judge Panels
Three judges each provide scores that contribute to the final total:
- **Building Judge**: Stunt, Pyramid, Tosses + Creativity/Showmanship
- **Tumbling Judge**: Standing, Running, Jumps + Creativity/Showmanship
- **Overall Judge**: Dance, Formations + Creativity/Showmanship

### Score Calculation Flow
1. Each category has Difficulty + Execution + optional Drivers
2. Creativity and Showmanship are averaged across all 3 judges
3. Raw Score = sum of all category totals
4. Final Score = Raw Score - Deductions

### Deduction Values
- Athlete Fall: 0.15
- Major Athlete Fall: 0.25
- Building Bobble: 0.25
- Building Fall: 0.75
- Major Building Fall: 1.25
- Boundary/Time Violations: 0.05

### Quantity Chart
Group requirements scale with athlete count (5-38 athletes):
- 31+: majority=5, most=6, max=7
- 23-30: majority=4, most=5, max=6
- 18-22: majority=3, most=4, max=5
- 12-17: majority=2, most=3, max=4
- <12: majority=1, most=2, max=3

## Database Export Format

The `exportForDatabase()` function outputs JSON structured for Supabase:
- `team_info`: Team metadata
- `performance`: Competition details and final scores
- `scores_building`, `scores_tumbling`, `scores_overall`: Category breakdowns
- `deductions`: Array of non-zero deductions with counts

## Tech Stack

- React 18 with hooks (useState, useEffect)
- Tailwind CSS for styling
- No external state management (local component state only)
