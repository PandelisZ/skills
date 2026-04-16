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

**Direct next steps:**
- "Next steps:"
- "Recommended:"
- "TODO:"
- "Action items:"
- "What to do next:"
- "Follow-up:"
- "Remaining work:"
- "Still to do:"
- "Future improvements:"

**Codex continuation offers (CRITICAL - these often go unactioned):**
- "If you want, I can keep driving..."
- "If you want, the next..."
- "If you want, the next step can be..."
- "What is still in flight:"
- "We could continue..."
- "The next phase would be..."

**Any numbered or bulleted lists of next actions after a summary or progress report**

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

## Special Pattern: Codex Continuation Offers

A **critical activation** is when Codex offers to continue work with phrases like:

- "If you want, I can..."
- "If you want, the next..."
- "We could continue..."

**These are not suggestions for YOU to do - they're offers from Codex to keep going.**

### How to Handle Continuation Offers

**Your response must be:**
> "Yes, let's continue. [Restate what they'll do]..."

Then **immediately proceed** with the work. Do not:
- Ask "should I continue?" (Codex already asked)
- End the session (defeats the purpose)
- Wait for explicit confirmation (the offer IS the confirmation prompt)

### The "Still in Flight" Pattern

When Codex lists "what is still in flight" or pending items, this is a **status report of incomplete work**. Treat it as a work queue:

1. Acknowledge the status
2. Pick the first item
3. Complete it
4. Move to the next
5. Report completion of all items

**Critical distinction:** "In flight" items are **blocking continuation** of the main task. They must be resolved.

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

### Example 1: Standard Next Steps

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

### Example 2: Codex "Still in Flight" Pattern

**Codex says:**
> "What is still in flight:
> - cmd+shift+[ / ] to move tabs left/right
> - cmd+w to close the current tab or extracted pane
> - cmd+option+h/j/k/l to move the pane itself instead of just focus it"

**❌ Without this skill (thread ends):**
> User: "OK great" 
> [Nothing happens - features remain unimplemented]

**✅ With this skill:**
> "I'll implement those keyboard shortcuts now. Starting with tab movement..."
> [Implements cmd+shift+[ / ] for tab movement]
> [Implements cmd+w for closing tabs/panes]
> [Implements cmd+option+hjkl for pane movement]
>
> "✅ All keyboard shortcuts implemented and tested. What's next?"

### Example 3: Codex Continuation Offer

**Codex says:**
> "If you want, I can keep driving the kernel build in the next turn and continue straight into initramfs assembly and QEMU boot once it finishes."

**❌ Without this skill (thread ends):**
> User: "Sounds good!"
> [User has to manually restart the next phase]

**✅ With this skill:**
> "Yes, let's continue. Driving the kernel build now..."
> [Continues directly into the work without waiting for next turn]
> [Seamlessly transitions to initramfs assembly]
> [Proceeds to QEMU boot testing]
>
> "Kernel build complete, initramfs assembled, and successfully booted in QEMU. What's the next milestone?"

### Example 4: Next Ergonomic Pass

**Codex says:**
> "If you want, the next ergonomic pass could be:
> - drag the header to reposition within the split
> - drag split dividers to resize
> - click the new button to pop that pane back into its own tab
>
> If you want, the next step can be the full multi-window version of that same action."

**✅ With this skill:**
> "I'll implement the full ergonomic pass now, starting with drag-to-reposition..."
> [Implements all listed interactions]
> [Proceeds to multi-window version without prompting]
>
> "Full ergonomic interaction set complete, including multi-window support. Ready for the next phase?"
