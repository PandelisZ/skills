#!/usr/bin/env bash
#
# Setup script for npx skills compatibility
# This script checks dependencies, validates the skills directory structure,
# and provides usage instructions for installing and using skills.
#

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SKILLS_DIR="${SCRIPT_DIR}/skills"

# Help message
show_help() {
    cat << 'EOF'
Usage: ./setup.sh [OPTIONS]

Setup script for npx skills compatibility.

OPTIONS:
    -h, --help      Show this help message and exit
    -c, --check     Check dependencies and directory structure only
    -l, --list      List all available skills
    -i, --install   Show installation instructions

DESCRIPTION:
    This script verifies that your system has the required dependencies
    (node, npm, npx) and that the skills directory structure is valid.
    It provides guidance on installing and using skills globally or locally.

EXAMPLES:
    ./setup.sh              Run full setup check
    ./setup.sh --help       Show this help message
    ./setup.sh --check      Check dependencies only
    ./setup.sh --list       List available skills
    ./setup.sh --install    Show installation options

SKILLS INSTALLATION METHODS:

1. Global Installation (recommended for daily use):
   npm install -g @anysphere/cursor-skills

2. Local Usage via npx:
   npx @anysphere/cursor-skills <command>

3. Local Development (symlink to ~/.cursor/skills/):
   ln -s "$(pwd)/skills" ~/.cursor/skills/local-dev

For more information, see README.md
EOF
}

# Print colored output
print_error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if a command exists
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Check Node.js installation
check_node() {
    if check_command node; then
        local version
        version=$(node --version)
        print_success "Node.js found: ${version}"
        return 0
    else
        print_error "Node.js is not installed"
        echo ""
        echo "To install Node.js:"
        echo "  - macOS:     brew install node"
        echo "  - Ubuntu:    sudo apt-get install nodejs npm"
        echo "  - Windows:   Download from https://nodejs.org/"
        echo "  - Other:     See https://nodejs.org/en/download/"
        return 1
    fi
}

# Check npm installation
check_npm() {
    if check_command npm; then
        local version
        version=$(npm --version)
        print_success "npm found: ${version}"
        return 0
    else
        print_error "npm is not installed"
        echo ""
        echo "npm is typically installed with Node.js."
        echo "Please install Node.js to get npm: https://nodejs.org/"
        return 1
    fi
}

# Check npx installation
check_npx() {
    if check_command npx; then
        local version
        version=$(npx --version)
        print_success "npx found: ${version}"
        return 0
    else
        print_error "npx is not installed"
        echo ""
        echo "npx is included with npm 5.2.0 and later."
        echo "To update npm (and get npx): npm install -g npm"
        return 1
    fi
}

# Check all dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    echo ""

    local has_errors=0

    if ! check_node; then
        has_errors=1
    fi
    echo ""

    if ! check_npm; then
        has_errors=1
    fi
    echo ""

    if ! check_npx; then
        has_errors=1
    fi
    echo ""

    return ${has_errors}
}

# Check if YAML frontmatter exists in SKILL.md file
validate_skill_frontmatter() {
    local skill_dir="$1"
    local skill_name
    skill_name=$(basename "${skill_dir}")
    local skill_md="${skill_dir}/SKILL.md"

    if [[ ! -f "${skill_md}" ]]; then
        print_error "Missing SKILL.md in ${skill_name}/"
        return 1
    fi

    # Check for YAML frontmatter
    if head -5 "${skill_md}" | grep -q '^---$'; then
        # Check for required fields
        local has_name=false
        local has_description=false

        if grep -q '^name:' "${skill_md}"; then
            has_name=true
        fi

        if grep -q '^description:' "${skill_md}"; then
            has_description=true
        fi

        if [[ "${has_name}" == true && "${has_description}" == true ]]; then
            return 0
        else
            print_warning "Invalid YAML frontmatter in ${skill_name}/SKILL.md (missing name or description)"
            return 1
        fi
    else
        print_warning "No YAML frontmatter found in ${skill_name}/SKILL.md"
        return 1
    fi
}

# Check directory structure
check_directory_structure() {
    print_info "Checking skills directory structure..."
    echo ""

    if [[ ! -d "${SKILLS_DIR}" ]]; then
        print_error "Skills directory not found at: ${SKILLS_DIR}"
        return 1
    fi

    local skill_count=0
    local valid_skills=0
    local invalid_skills=0

    for skill_dir in "${SKILLS_DIR}"/*/; do
        # Skip if not a directory
        [[ -d "${skill_dir}" ]] || continue

        skill_count=$((skill_count + 1))

        if validate_skill_frontmatter "${skill_dir}"; then
            valid_skills=$((valid_skills + 1))
        else
            invalid_skills=$((invalid_skills + 1))
        fi
    done

    echo ""
    print_success "Found ${skill_count} skill directories"

    if [[ ${invalid_skills} -gt 0 ]]; then
        print_warning "${invalid_skills} skills have invalid or missing YAML frontmatter"
    fi

    if [[ ${valid_skills} -eq ${skill_count} && ${skill_count} -gt 0 ]]; then
        print_success "All skills have valid YAML frontmatter"
    fi

    return 0
}

# Extract description from YAML frontmatter in SKILL.md
# Handles single-line and multi-line (>-, |, >) YAML formats
extract_description() {
    local file="$1"
    local in_description=0
    local description=""
    local indent=""
    
    while IFS= read -r line; do
        # Check for end of YAML frontmatter
        if [[ "$line" == "---" && -n "$description" ]]; then
            break
        fi
        
        # Check if we are starting a description field
        if [[ $in_description -eq 0 && "$line" =~ ^description: ]]; then
            # Single line description: description: "text" or description: text
            local after_colon="${line#description:}"
            after_colon="${after_colon# }"  # remove leading space
            
            # Check if it is a multi-line indicator (>-, >, |-, |, or empty)
            if [[ "$after_colon" =~ ^(>[-]?|\|[-]?|>)?$ ]]; then
                # Multi-line: start collecting indented lines
                in_description=1
                indent=""
                continue
            elif [[ -n "$after_colon" ]]; then
                # Single line description (remove quotes if present)
                description="${after_colon#\"}"
                description="${description%\"}"
                description="${after_colon#'}"
                description="${description%'}"
                break
            fi
        fi
        
        # Collecting multi-line description
        if [[ $in_description -eq 1 ]]; then
            # Empty line - add to description
            if [[ -z "$line" ]]; then
                description="${description} "
                continue
            fi
            
            # Determine base indent from first non-empty line
            if [[ -z "$indent" && "$line" =~ ^[[:space:]] ]]; then
                indent="${line%%[^[:space:]]*}"
            fi
            
            # Check if line is still indented (part of description)
            if [[ "$line" =~ ^[[:space:]] || -z "$line" ]]; then
                # Remove base indent
                local content="$line"
                if [[ -n "$indent" && "$content" == "$indent"* ]]; then
                    content="${content#$indent}"
                elif [[ "$content" =~ ^[[:space:]] ]]; then
                    # Remove leading whitespace
                    content="${content#${content%%[^[:space:]]*}}"
                fi
                
                if [[ -n "$description" ]]; then
                    description="${description} ${content}"
                else
                    description="${content}"
                fi
            else
                # Line not indented - end of description
                break
            fi
        fi
    done < "$file"
    
    # Trim trailing whitespace
    description="${description% }"
    echo "$description"
}

# List all available skills
list_skills() {
    print_info "Available skills:"
    echo ""

    if [[ ! -d "${SKILLS_DIR}" ]]; then
        print_error "Skills directory not found"
        return 1
    fi

    for skill_dir in "${SKILLS_DIR}"/*/; do
        [[ -d "${skill_dir}" ]] || continue

        local skill_name
        skill_name=$(basename "${skill_dir}")
        local skill_md="${skill_dir}/SKILL.md"
        local description=""

        if [[ -f "${skill_md}" ]]; then
            # Extract description from YAML frontmatter
            description=$(extract_description "${skill_md}")
        fi

        if [[ -n "${description}" ]]; then
            printf "  %-30s %s\n" "${skill_name}" "${description}"
        else
            echo "  ${skill_name}"
        fi
    done
}

# Show installation instructions
show_install_instructions() {
    cat << 'EOF'

╔════════════════════════════════════════════════════════════════╗
║              SKILL INSTALLATION OPTIONS                        ║
╚════════════════════════════════════════════════════════════════╝

1. GLOBAL INSTALLATION (Recommended for daily use)
   ─────────────────────────────────────────────────────────────
   Install the skills package globally using npm:

       npm install -g @anysphere/cursor-skills

   Once installed, use skills directly:

       cursor-skills <command>

2. LOCAL USAGE VIA NPX (No installation required)
   ─────────────────────────────────────────────────────────────
   Run skills directly without installing:

       npx @anysphere/cursor-skills <command>

   This is useful for one-off usage or CI/CD pipelines.

3. LOCAL DEVELOPMENT (Symlink for development)
   ─────────────────────────────────────────────────────────────
   For local development and testing, symlink this directory:

       ln -s "$(pwd)/skills" ~/.cursor/skills/local-dev

   Or set the CODEX_HOME environment variable:

       export CODEX_HOME="$(pwd)"

   Skills will be loaded from: ${CODEX_HOME}/skills/

4. PROJECT-LOCAL INSTALLATION
   ─────────────────────────────────────────────────────────────
   Install as a dev dependency in your project:

       npm install --save-dev @anysphere/cursor-skills

   Then use via npm scripts in package.json.

═══════════════════════════════════════════════════════════════════

DIRECTORY STRUCTURE:

  skills/
    <skill-name>/
      SKILL.md          # Skill definition with YAML frontmatter
      agents/           # Agent configurations
      ...               # Additional assets/scripts

Each SKILL.md must have YAML frontmatter with:
  - name: Skill identifier
  - description: Brief description of the skill

═══════════════════════════════════════════════════════════════════

For more information, see README.md

EOF
}

# Main setup function
run_setup() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           SKILLS SETUP VERIFICATION                            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    local has_errors=0

    if ! check_dependencies; then
        has_errors=1
    fi

    if ! check_directory_structure; then
        has_errors=1
    fi

    echo ""
    if [[ ${has_errors} -eq 0 ]]; then
        print_success "Setup verification completed successfully!"
        echo ""
        show_install_instructions
    else
        print_error "Setup verification completed with errors."
        echo ""
        echo "Please fix the issues above and run again."
        exit 1
    fi
}

# Main entry point
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--check)
            check_dependencies
            check_directory_structure
            exit $?
            ;;
        -l|--list)
            list_skills
            exit 0
            ;;
        -i|--install)
            show_install_instructions
            exit 0
            ;;
        "")
            run_setup
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

main "$@"
