# @pandelis/skills

A curated collection of 19 agent skills for AI coding assistants. These skills extend Codex, Cursor, Claude Code, and other AI agents with specialized capabilities for development workflows.

## Quick Start

```bash
# Clone and setup
git clone https://github.com/pandelisz/skills.git
cd skills
./setup.sh

# Or install via npx skills
npx skills add pandelis/skills
```

## Skills Overview

### 🎯 Core Agent Skills
Skills for managing and extending AI agents themselves.

| Skill | Description |
|-------|-------------|
| **create-skill** | Guides users through creating effective Agent Skills. Use when you want to create, write, or author a new skill, or asks about skill structure, best practices, or SKILL.md format. |
| **create-subagent** | Create custom subagents for specialized AI tasks. Use when you want to create a new type of subagent, set up task-specific agents, configure code reviewers, debuggers, or domain-specific assistants with custom prompts. |
| **create-rule** | Create agent rules for persistent AI guidance. Use when you want to create a rule, add coding standards, set up project conventions, configure file-specific patterns, create RULE.md files, or asks about .cursor/rules/ or AGENTS.md. |
| **create-hook** | Create agent hooks. Use when you want to create a hook, write hooks.json, add hook scripts, or automate behavior around agent events. |
| **migrate-to-skills** | Convert 'Applied intelligently' Cursor rules (.cursor/rules/*.mdc) and slash commands (.cursor/commands/*.md) to Agent Skills format (.cursor/skills/). Use when you want to migrate rules or commands to skills. |
| **codex-continue-iterating** | **CRITICAL**: Monitor and continue executing Codex rollout recommended next steps. Activates when Codex ends with recommendations like "Next steps:", "If you want, I can keep driving...", or "What is still in flight:" - ensures those recommendations are actually executed rather than letting the thread end with unactioned suggestions. |

### 🖥️ UI & Visualization
Skills for building rich user interfaces and visual outputs.

| Skill | Description |
|-------|-------------|
| **canvas** | A Canvas is a live React app rendered beside the chat. You MUST use a canvas when the agent produces a standalone analytical artifact — quantitative analyses, billing investigations, security audits, architecture reviews, data-heavy content, timelines, charts, tables, interactive explorations, repeatable tools, or any response that benefits from visual layout. |
| **screenshot** | Use when the user explicitly asks for a desktop or system screenshot (full screen, specific app or window, or a pixel region), or when tool-specific capture capabilities are unavailable and an OS-level capture is needed. |
| **statusline** | Configure a custom status line in the CLI. Use when the user mentions status line, statusline, statusLine, CLI status bar, prompt footer customization, or wants to add session context above the prompt. |
| **storybook-visual-review** | Review Storybook stories visually, compare states, and capture screenshots for design iteration. Use when the task involves opening a Storybook instance, navigating to one or more stories, inspecting layout and tool-call rendering, or capturing screenshots through browser MCP tools or a Storybook MCP if one is available. |

### 🧪 Testing & Browser Automation
Skills for automated testing and browser interaction.

| Skill | Description |
|-------|-------------|
| **playwright** | Use when the task requires automating a real browser from the terminal (navigation, form filling, snapshots, screenshots, data extraction, UI-flow debugging) via playwright-cli or the bundled wrapper script. |
| **playwright-interactive** | Persistent browser and Electron interaction through `js_repl` for fast iterative UI debugging. |

### 🚀 Deployment & Operations
Skills for deploying and managing production systems.

| Skill | Description |
|-------|-------------|
| **kamal-deployment** | Help with Kamal deployment workflows for setup, deploy, rollback, production log diagnostics, and Docker registry configuration for local or cross-host image publishing. |
| **vex-desktop-harness** | Launch, build, diagnose, and stop the Vex desktop surfaces from `/Users/pz/w/vex/desktop`. Use when Codex needs to run Storybook, the standalone Vite shell, or the real Tauri desktop app; inspect ports, readiness, and logs; troubleshoot desktop boot failures; or prepare the app for screenshot-based visual verification. |

### 🛠️ Utilities
General-purpose utility skills.

| Skill | Description |
|-------|-------------|
| **shell** | Runs the rest of a /shell request as a literal shell command. Use only when the user explicitly invokes /shell and wants the following text executed directly in the terminal. |
| **babysit** | Keep a PR merge-ready by triaging comments, resolving clear conflicts, and fixing CI in a loop. |
| **update-cli-config** | View and modify Cursor CLI configuration settings in ~/.cursor/cli-config.json. Use when the user wants to change CLI settings, configure permissions, switch approval mode, enable vim mode, toggle display options, configure sandbox, or manage any CLI preferences. |
| **update-cursor-settings** | Modify Cursor/VSCode user settings in settings.json. Use when you want to change editor settings, preferences, configuration, themes, font size, tab size, format on save, auto save, keybindings, or any settings.json values. |

### 📦 Skill Containers
Composite skills that contain multiple sub-skills.

| Skill | Description |
|-------|-------------|
| **codex-primary-runtime** | Container for Codex primary runtime skills including PowerPoint slides and Excel spreadsheets. Contains sub-skills: `slides/`, `spreadsheets/`. |

## Installation

### Method 1: Direct Clone (Recommended for development)

```bash
git clone https://github.com/pandelisz/skills.git ~/.cursor/skills
# or
git clone https://github.com/pandelisz/skills.git ~/.codex/skills
```

### Method 2: Using setup.sh

```bash
git clone https://github.com/pandelisz/skills.git
cd skills
./setup.sh --install
```

### Method 3: Using npx skills

```bash
npx skills add pandelis/skills
```

### Method 4: Symlink (keeps git repo separate)

```bash
git clone https://github.com/pandelisz/skills.git ~/dev/skills
ln -s ~/dev/skills ~/.cursor/skills
# or
ln -s ~/dev/skills ~/.codex/skills
```

## Skill Structure

Each skill follows the Agent Skills Specification:

```
skills/
  <skill-name>/
    SKILL.md              # Required - skill instructions and metadata
    agents/
      openai.yaml         # UI metadata for agent interfaces
    scripts/              # Optional - utility scripts
    references/           # Optional - documentation references
    assets/               # Optional - templates, images, etc.
```

## Usage Examples

### Continue iterating on Codex recommendations

When Codex says:
> "If you want, I can keep driving the kernel build in the next turn..."

The `codex-continue-iterating` skill activates and automatically continues the work without requiring you to manually restart.

### Create a new skill

```
User: "I want to create a skill for deploying to Kubernetes"
[create-skill activates]
Agent: "I'll guide you through creating a Kubernetes deployment skill..."
```

### Visual review with Storybook

```
User: "Check the Button component in Storybook"
[storybook-visual-review activates]
Agent: "Opening Storybook, navigating to Button component, capturing screenshot..."
```

### Canvas for data visualization

```
User: "Show me the analytics data"
[canvas activates]
Agent: "Creating a canvas with interactive charts for your analytics..."
```

## Creating New Skills

See `skills/create-skill/SKILL.md` for the full skill authoring guide, or use the skill itself:

```
User: "Help me create a new skill"
[create-skill activates and guides you through the process]
```

## Commands

```bash
# Check setup
./setup.sh --check

# List all skills
./setup.sh --list

# Install skills to agent directories
./setup.sh --install
```

## License

MIT
