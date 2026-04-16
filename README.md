# Agent Skills Repository

A git-managed collection of reusable agent skills for AI coding assistants.

## Structure

```
skills/
  <skill-name>/
    SKILL.md           # Required - skill instructions and metadata
    agents/
      openai.yaml      # UI metadata for agent interfaces
    scripts/           # Optional - utility scripts
    references/        # Optional - documentation references
    assets/            # Optional - templates, images, etc.
```

## Installation

### Cursor
Copy or symlink skills to `~/.cursor/skills/`

### Codex
Copy or symlink skills to `~/.codex/skills/`

### Cosine (Ultra)
Skills are automatically discovered from this repository.

## Creating New Skills

See `skill-creator/SKILL.md` for the full skill authoring guide.
