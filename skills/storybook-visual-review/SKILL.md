---
name: storybook-visual-review
description: Review Storybook stories visually, compare states, and capture screenshots for design iteration. Use when the task involves opening a Storybook instance, navigating to one or more stories, inspecting layout and tool-call rendering, or capturing screenshots through browser MCP tools or a Storybook MCP if one is available.
---

# Storybook Visual Review

Open Storybook stories directly and inspect them in isolation instead of booting the whole app. Capture screenshots and note visual issues precisely enough that the next edit can be targeted.

## Workflow

1. Identify the Storybook entrypoint.
2. Open the Storybook UI with browser MCP tools. If a Storybook-specific MCP is available in the environment, prefer it for story navigation and story metadata.
3. Navigate to the target story or story set.
4. Inspect the rendered result with accessibility snapshots first. Use screenshots when visual layout, spacing, colors, or overflow need confirmation.
5. If the task is comparative, capture before and after screenshots at the same viewport size.

## Entrypoint Rules

- If the project already documents a Storybook command, use it.
- If Storybook was just added in the repo, use the package-local script, usually `pnpm storybook`.
- If the user names a specific story id, navigate directly to that story.
- If the user asks for a broad review, start at the Storybook sidebar and inspect the relevant section in sequence.

## Browser MCP Procedure

- Start with browser navigation to the Storybook URL.
- Use accessibility snapshots to locate story names, tabs, controls, and rendered content.
- Use browser clicks instead of guessing URL fragments when the exact story id is unknown.
- Set an explicit viewport size before taking screenshots so repeated comparisons are consistent.
- Take full-page screenshots only when the story is taller than the viewport. Otherwise use viewport screenshots.

## Storybook MCP Preference

- If a Storybook MCP is available, prefer it for:
- Enumerating stories
- Selecting a story by title or id
- Reading args or controls state
- Jumping between variations quickly

- Fall back to browser MCP whenever:
- The Storybook MCP is unavailable
- The MCP cannot access the running instance
- A visual check still requires an actual browser rendering or screenshot

## Screenshot Rules

- Capture screenshots after the story has fully rendered and any loading skeletons are gone.
- Keep viewport width stable across related screenshots.
- When reviewing variants, capture one screenshot per state rather than one large stitched image unless the user asked for a contact sheet.
- If browser screenshots are insufficient, use the `$screenshot` skill for OS-level capture.

## Review Output

When reporting findings from a Storybook review:

- Name the story exactly as shown in Storybook.
- Mention viewport size if it matters.
- Separate structural issues from cosmetic issues.
- Call out tool-call cards, command output blocks, badges, and scroll behavior explicitly for thread-oriented UIs.

## Typical Requests

- "Open the ThreadView story and tell me what looks off."
- "Capture the RightRail story in logged-out and approvals states."
- "Compare tool call rendering before and after my changes."
- "Review all thread-related stories at desktop width."
