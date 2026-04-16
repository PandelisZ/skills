---
name: codex-continue-iterating
description: >-
  Monitor and continue executing Codex rollout recommended next steps. Activates
  when Codex ends with recommendations like "Next steps:", "Recommended:", or
  "TODO:" - ensures those recommendations are actually executed rather than
  letting the thread end with unactioned suggestions. Tracks completion status
  and re-engages users on pending items.
metadata:
  surfaces:
    - ide
---

# Continue Iterating on Codex Recommendations

When a Codex rollout ends with a list of recommended next steps, **do not let the thread end there**. This skill ensures recommendations are parsed, prioritized, and executed.

## Activation Patterns

Activate this skill when Codex outputs contain any of these patterns at the end:

- "Next steps:"
- "Recommended:"
- "TODO:"
- "Action items:"
- "What to do next:"
- "Follow-up:"
- "Remaining work:"
- "Still to do:"
- "Future improvements:"
- Numbered or bulleted lists of next actions after a summary

## Workflow

### 1. Detect and Parse Recommendations

When you see next steps at the end of a Codex response:

1. **Extract the recommendations** - Copy the exact items from the Codex output
2. **Categorize each item**:
   - 🔴 **Critical** - Blocking issues, bugs, or required fixes
   - 🟡 **Important** - Significant improvements or missing features
   - 🟢 **Nice to have** - Optional enhancements or optimizations

### 2. Create an Execution Plan

Transform recommendations into actionable tasks:

```
Recommendation: "Add error handling for edge cases"
→ Action: Implement try-catch blocks and validation
→ Files to check: [list relevant files]
```

### 3. Execute - Don't Just List

**The key principle**: Actually DO the recommendations, don't just acknowledge them.

- For code changes: Make the edits
- For tests: Write and run them
- For documentation: Draft it
- For reviews: Create the PR and request review

### 4. Track Completion Status

Maintain a running checklist:

```markdown
## Progress on Recommendations

- [x] Fix authentication bug in login.ts
- [x] Add unit tests for auth flow
- [ ] Update API documentation (pending user review)
- [ ] Optimize database queries (deferred)
```

### 5. Re-engage on Pending Items

Before completing, explicitly address pending items with the user:

> "I've completed 2 of 4 recommendations. For the remaining items:
> 
> 1. **API documentation** - Should I proceed with updating the docs?
> 2. **Query optimization** - This is lower priority; shall we defer or include?"

## Prioritization Logic

When deciding what to tackle first:

1. **Fixes before features** - Bug fixes and error handling come first
2. **Blocking before optional** - Items that block other work take priority
3. **Tests with code** - Write tests alongside the code they validate
4. **Documentation last** - Update docs once implementation is finalized

## Common Recommendation Types

### Code Quality
- "Add error handling" → Implement comprehensive error handling
- "Add input validation" → Add validation logic and tests
- "Refactor for readability" → Restructure with clear naming

### Testing
- "Add tests" → Write unit/integration tests with good coverage
- "Increase test coverage" → Identify gaps and fill them

### Documentation
- "Update README" → Refresh documentation with current usage
- "Add inline comments" → Document complex logic

### Integration
- "Create a PR" → Commit, push, and open PR with proper description
- "Get review" → Request review from appropriate team members

## Anti-Patterns to Avoid

❌ **Ending with "Here are the next steps"** - The skill exists to prevent this
❌ **Passive acknowledgment** - Don't just say "I'll do this" - actually do it
❌ **Losing context** - Don't start a new thread; continue the current one
❌ **Partial execution** - Don't skip items without explicit user direction

## Example Session Flow

**Codex says:**
> "I've implemented the basic feature. Next steps:
> 1. Add error handling for network failures
> 2. Write unit tests
> 3. Update the documentation"

**You respond with this skill:**
> "I'll execute those recommendations now. Starting with error handling..."

**After executing:**
> "Completed all recommendations:
> - ✅ Added try-catch blocks for network errors in api.ts
> - ✅ Wrote unit tests covering success and failure cases
> - ✅ Updated README with new usage examples
>
> The feature is now complete and ready for use."
