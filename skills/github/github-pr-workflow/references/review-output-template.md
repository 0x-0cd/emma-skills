# Code Review Output Template

Use this format when presenting code review results:

## Code Review Summary

### Critical
- **file:line** — Description of critical issue. Suggestion: How to fix.

### Warnings
- **file:line** — Description of warning-level issue.

### Suggestions
- **file:line** — Description of minor suggestion.

### Looks Good
- What's done well.

For formal review submission with gh:
gh pr review $PR_NUMBER --request-changes --body "See inline comments."
gh pr review $PR_NUMBER --approve --body "LGTM!"
