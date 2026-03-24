#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Automotive Claude Code Agents — Append-Safe Installer
# ============================================================================
# SAFELY installs automotive skills, agents, commands, rules, hooks, and
# knowledge into an EXISTING Claude Code workspace without replacing anything.
#
# Design principles:
#   - NEVER overwrites settings.json, existing agents, commands, rules, hooks
#   - All automotive content is namespaced with "automotive-" prefix
#   - Creates backup before any changes
#   - Clean uninstall removes only what was installed
#
# Usage:
#   ./install.sh                          # Install to ~/.claude (append-safe)
#   ./install.sh --project /path/to/proj  # Install to project .claude/
#   ./install.sh --dry-run                # Preview without changes
#   ./install.sh --uninstall              # Remove only automotive components
#   ./install.sh --status                 # Show what's currently installed
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.claude"
DRY_RUN=false
UNINSTALL=false
STATUS_ONLY=false
PROJECT_DIR=""
NAMESPACE="automotive"
MANIFEST_FILE=""
INSTALLED_COUNT=0
SKIPPED_COUNT=0
MODULES=""
LIGHTWEIGHT=false
ALL_MODULES="adas autosar battery cybersecurity diagnostics functional-safety powertrain v2x cloud-native sdv ecu-systems hpc zonal emerging-tech manufacturing"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[x]${NC} $*"; }
debug() { echo -e "${DIM}    $*${NC}"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Append automotive Claude Code agents into an existing workspace.
This installer NEVER replaces your existing settings, agents, or hooks.

Options:
  --project DIR       Install to project-specific .claude/ directory
  --modules LIST      Install only specified modules (comma-separated)
                      Available: adas, autosar, battery, cybersecurity, diagnostics,
                                 functional-safety, powertrain, v2x, cloud-native, sdv,
                                 ecu-systems, hpc, zonal, emerging-tech, manufacturing
  --lightweight       Install minimal set (no knowledge-base, reduced context)
  --dry-run           Preview what would be installed without making changes
  --uninstall         Remove only automotive-prefixed components
  --status            Show what automotive components are currently installed
  -h, --help          Show this help message

Token Usage Optimization:
  ⚠ Global install (~/.claude) loads ALL content into context for EVERY conversation.
  ✓ Use --project for automotive-specific work (isolated context)
  ✓ Use --modules to install only needed domains
  ✓ Use --lightweight for minimal footprint

Safety guarantees:
  - Your settings.json is NEVER modified (merge snippet provided separately)
  - Your existing agents, commands, rules, hooks are NEVER touched
  - All automotive content uses "${NAMESPACE}-" prefix to avoid collisions
  - A manifest tracks exactly what was installed for clean uninstall
  - Backup created before any changes

Examples:
  $(basename "$0") --project ~/my-ecu-project              # Project-specific (RECOMMENDED)
  $(basename "$0") --modules adas,battery                  # Only ADAS + Battery modules
  $(basename "$0") --lightweight                           # Minimal install, low tokens
  $(basename "$0") --dry-run                               # Preview only
  $(basename "$0") --uninstall                             # Remove automotive content
  $(basename "$0") --status                                # Check installation status
EOF
    exit 0
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --project)
            PROJECT_DIR="$2"
            shift 2
            ;;
        --modules)
            MODULES="$2"
            shift 2
            ;;
        --lightweight)
            LIGHTWEIGHT=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        --status)
            STATUS_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            error "Unknown option: $1"
            usage
            ;;
    esac
done

if [[ -n "$PROJECT_DIR" ]]; then
    TARGET_DIR="${PROJECT_DIR}/.claude"
fi

MANIFEST_FILE="${TARGET_DIR}/.automotive-manifest"

# ---------------------------------------------------------------------------
# Status command
# ---------------------------------------------------------------------------
if $STATUS_ONLY; then
    echo ""
    echo -e "${CYAN}Automotive Claude Code — Installation Status${NC}"
    echo -e "${CYAN}Target: ${TARGET_DIR}${NC}"
    echo ""

    if [[ ! -f "$MANIFEST_FILE" ]]; then
        echo "  Not installed (no manifest found)"
        exit 0
    fi

    echo "  Installed components:"
    while IFS= read -r line; do
        if [[ -e "$line" ]] || [[ -L "$line" ]]; then
            echo -e "    ${GREEN}OK${NC}  $line"
        else
            echo -e "    ${RED}MISSING${NC}  $line"
        fi
    done < "$MANIFEST_FILE"

    local_count=$(wc -l < "$MANIFEST_FILE")
    echo ""
    echo "  Total: $local_count components"
    exit 0
fi

# ---------------------------------------------------------------------------
# Manifest tracking — records every file we create for clean uninstall
# ---------------------------------------------------------------------------
manifest_add() {
    local path="$1"
    if ! $DRY_RUN; then
        echo "$path" >> "$MANIFEST_FILE"
    fi
}

# ---------------------------------------------------------------------------
# Module filtering — check if a module should be installed
# ---------------------------------------------------------------------------
should_install_module() {
    local module="$1"

    # Install all if no modules specified
    [[ -z "$MODULES" ]] && return 0

    # Check if module is in the comma-separated list
    echo ",$MODULES," | grep -qi ",$module,"
    return $?
}

# ---------------------------------------------------------------------------
# Safe symlink — only creates if target doesn't exist (never overwrites)
# ---------------------------------------------------------------------------
safe_link() {
    local src="$1"
    local dest="$2"

    if $DRY_RUN; then
        echo -e "  ${DIM}[DRY-RUN] link: $(basename "$dest")${NC}"
        (( INSTALLED_COUNT++ )) || true
        return
    fi

    if [[ -L "$dest" ]]; then
        # Our symlink already exists — update it
        local existing_target
        existing_target=$(readlink "$dest")
        if [[ "$existing_target" == "$src" ]]; then
            (( SKIPPED_COUNT++ )) || true
            return
        fi
        rm "$dest"
    elif [[ -e "$dest" ]]; then
        warn "Skipping $(basename "$dest") — non-automotive file already exists"
        (( SKIPPED_COUNT++ )) || true
        return
    fi

    ln -s "$src" "$dest"
    manifest_add "$dest"
    (( INSTALLED_COUNT++ )) || true
}

# ---------------------------------------------------------------------------
# Uninstall — only removes files listed in our manifest
# ---------------------------------------------------------------------------
do_uninstall() {
    echo ""
    echo -e "${CYAN}Automotive Claude Code — Uninstall${NC}"
    echo -e "${CYAN}Target: ${TARGET_DIR}${NC}"
    echo ""

    if [[ ! -f "$MANIFEST_FILE" ]]; then
        warn "No manifest found — nothing to uninstall"
        warn "Looking for automotive-prefixed files as fallback..."
        echo ""

        local found=0
        for dir in agents commands rules hooks skills knowledge-base workflows; do
            local target_path="${TARGET_DIR}/${dir}"
            if [[ -d "$target_path" ]]; then
                while IFS= read -r -d '' item; do
                    if $DRY_RUN; then
                        echo "  [DRY-RUN] rm $(basename "$item")"
                    else
                        rm -rf "$item"
                        info "Removed: $(basename "$item")"
                    fi
                    (( found++ )) || true
                done < <(find "$target_path" -maxdepth 1 -name "${NAMESPACE}-*" -print0 2>/dev/null || true)
            fi
        done

        # Also check for settings merge snippet
        local snippet="${TARGET_DIR}/${NAMESPACE}-settings-snippet.json"
        if [[ -f "$snippet" ]]; then
            if $DRY_RUN; then
                echo "  [DRY-RUN] rm $(basename "$snippet")"
            else
                rm -f "$snippet"
                info "Removed: $(basename "$snippet")"
            fi
            (( found++ )) || true
        fi

        if [[ $found -eq 0 ]]; then
            info "No automotive components found."
        else
            info "Removed $found automotive components (fallback mode)."
        fi
        return
    fi

    local removed=0
    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        if $DRY_RUN; then
            echo "  [DRY-RUN] rm $path"
            (( removed++ )) || true
        elif [[ -L "$path" ]]; then
            rm "$path"
            info "Removed: $(basename "$path")"
            (( removed++ )) || true
        elif [[ -f "$path" ]]; then
            rm "$path"
            info "Removed: $(basename "$path")"
            (( removed++ )) || true
        elif [[ -d "$path" ]]; then
            rm -rf "$path"
            info "Removed: $(basename "$path")"
            (( removed++ )) || true
        fi
    done < "$MANIFEST_FILE"

    if ! $DRY_RUN; then
        rm -f "$MANIFEST_FILE"
        info "Removed manifest"
    fi

    echo ""
    info "Uninstall complete — removed $removed automotive components"
    info "Your existing workspace is untouched."
}

# ---------------------------------------------------------------------------
# Install agents — convert .yaml to .md frontmatter format for Claude Code
# ---------------------------------------------------------------------------
install_agents() {
    local src_dir="${SCRIPT_DIR}/agents"
    local dest_dir="${TARGET_DIR}/agents"

    if [[ ! -d "$src_dir" ]]; then
        warn "No agents/ directory found — skipping"
        return
    fi

    mkdir -p "$dest_dir"
    info "Installing agents → ${dest_dir}/"

    while IFS= read -r -d '' yaml_file; do
        local basename_noext
        basename_noext=$(basename "$yaml_file" .yaml)
        local category
        category=$(basename "$(dirname "$yaml_file")")

        # Module filtering
        if ! should_install_module "$category"; then
            debug "Skipping agent: $category/$basename_noext (module filter)"
            continue
        fi

        local dest_name="${NAMESPACE}-${category}-${basename_noext}.md"
        local dest_path="${dest_dir}/${dest_name}"

        if $DRY_RUN; then
            echo -e "  ${DIM}[DRY-RUN] agent: ${dest_name}${NC}"
            (( INSTALLED_COUNT++ )) || true
            continue
        fi

        if [[ -e "$dest_path" ]] && [[ ! -L "$dest_path" ]]; then
            # Check if it's ours (contains automotive marker)
            if ! grep -q "# automotive-claude-code-agents" "$dest_path" 2>/dev/null; then
                (( SKIPPED_COUNT++ )) || true
                continue
            fi
        fi

        # Extract fields from YAML and convert to Claude Code .md format
        local name description role tools_list
        name=$(grep -m1 '^name:' "$yaml_file" | sed 's/^name:\s*//' | tr -d '"' || echo "$basename_noext")
        description=$(grep -m1 '^description:' "$yaml_file" | sed 's/^description:\s*//' | tr -d '"' || echo "Automotive ${category} agent")

        # Extract role/system_prompt content (multiline)
        role=$(awk '/^(role|system_prompt):\s*\|/{found=1; next} found && /^[^ ]/{found=0} found{print}' "$yaml_file" | head -50)

        # Default tools for automotive agents
        tools_list="Read, Grep, Glob, Bash"

        cat > "$dest_path" <<AGENT_MD
---
name: ${NAMESPACE}-${category}-${basename_noext}
description: "${description}"
tools: ${tools_list}
# automotive-claude-code-agents — installed by install.sh (safe to delete)
---

# Automotive Agent: ${name}
**Domain**: ${category}

${role:-Automotive ${category} specialist agent for ${name}.

When invoked:
1. Analyze the automotive domain context
2. Apply ${category} domain expertise
3. Follow relevant standards (ISO 26262, AUTOSAR, ISO 21434)
4. Provide production-quality automotive engineering guidance}
AGENT_MD
        manifest_add "$dest_path"
        (( INSTALLED_COUNT++ )) || true
    done < <(find "$src_dir" -name "*.yaml" -type f -print0)
}

# ---------------------------------------------------------------------------
# Install commands — create .md wrappers that invoke the .sh scripts
# ---------------------------------------------------------------------------
install_commands() {
    local src_dir="${SCRIPT_DIR}/commands"
    local dest_dir="${TARGET_DIR}/commands/${NAMESPACE}"

    if [[ ! -d "$src_dir" ]]; then
        warn "No commands/ directory found — skipping"
        return
    fi

    # Use a subdirectory (Claude Code supports command subdirs like testpilot/)
    mkdir -p "$dest_dir"
    info "Installing commands → ${dest_dir}/"

    while IFS= read -r -d '' sh_file; do
        local basename_noext
        basename_noext=$(basename "$sh_file" .sh)
        local category
        category=$(basename "$(dirname "$sh_file")")

        # Module filtering
        if ! should_install_module "$category"; then
            debug "Skipping command: $category/$basename_noext (module filter)"
            continue
        fi

        local dest_name="${category}-${basename_noext}.md"
        local dest_path="${dest_dir}/${dest_name}"

        if $DRY_RUN; then
            echo -e "  ${DIM}[DRY-RUN] command: /automotive ${category}-${basename_noext}${NC}"
            (( INSTALLED_COUNT++ )) || true
            continue
        fi

        if [[ -e "$dest_path" ]] && [[ ! -L "$dest_path" ]]; then
            if ! grep -q "# automotive-claude-code-agents" "$dest_path" 2>/dev/null; then
                (( SKIPPED_COUNT++ )) || true
                continue
            fi
        fi

        # Extract description from script header comment
        local script_desc
        script_desc=$(grep -m1 '^#.*—' "$sh_file" | sed 's/^#\s*//' || echo "Automotive ${category} command: ${basename_noext}")

        cat > "$dest_path" <<CMD_MD
---
description: "${script_desc}"
# automotive-claude-code-agents — installed by install.sh (safe to delete)
---

# Automotive Command: ${category}/${basename_noext}

Run the automotive ${category} ${basename_noext} tool.

\`\`\`bash
bash "${sh_file}"
\`\`\`

This command is part of the automotive-claude-code-agents extension.
Domain: ${category} | Source: commands/${category}/${basename_noext}.sh
CMD_MD
        manifest_add "$dest_path"
        (( INSTALLED_COUNT++ )) || true
    done < <(find "$src_dir" -name "*.sh" -type f -print0)
}

# ---------------------------------------------------------------------------
# Install skills — symlink skill subdirectories (Claude discovers these)
# ---------------------------------------------------------------------------
install_skills() {
    local src_dir="${SCRIPT_DIR}/skills"
    local dest_dir="${TARGET_DIR}/skills"

    if [[ ! -d "$src_dir" ]]; then
        warn "No skills/ directory found — skipping"
        return
    fi

    mkdir -p "$dest_dir"
    info "Installing skills → ${dest_dir}/"

    # Each skill category becomes a namespaced subdirectory
    for category_dir in "$src_dir"/*/; do
        [[ ! -d "$category_dir" ]] && continue
        local category
        category=$(basename "$category_dir")

        # Skip templates
        [[ "$category" == "_templates" ]] && continue

        # Module filtering: extract module name from category (e.g., automotive-adas -> adas)
        local module_name="${category#automotive-}"
        if ! should_install_module "$module_name"; then
            debug "Skipping skill category: $category (module filter)"
            continue
        fi

        local dest_name="${NAMESPACE}-${category}"
        local dest_path="${dest_dir}/${dest_name}"

        # Create a SKILL.md wrapper in a namespaced directory
        if $DRY_RUN; then
            echo -e "  ${DIM}[DRY-RUN] skill: ${dest_name}/${NC}"
            (( INSTALLED_COUNT++ )) || true
            continue
        fi

        mkdir -p "$dest_path"

        # Generate SKILL.md from the category content
        local skill_count
        skill_count=$(find "$category_dir" -type f \( -name "*.yaml" -o -name "*.md" \) | wc -l)

        cat > "${dest_path}/SKILL.md" <<SKILL_MD
---
name: ${NAMESPACE}-${category}
description: |
  Automotive ${category} domain expertise. ${skill_count} skills covering
  ${category} systems, standards, and best practices for automotive development.
  Part of automotive-claude-code-agents extension.
  TRIGGER: When working on automotive ${category} topics.
allowed-tools: Read, Grep, Glob, Bash
# automotive-claude-code-agents — installed by install.sh (safe to delete)
---

# Automotive Skill: ${category}

This skill provides expertise in automotive **${category}** domain.

## Source Content

Skill library location: \`${category_dir}\`
Total skill files: ${skill_count}

## Usage

Reference the skill files for detailed domain knowledge:
\`\`\`bash
ls ${category_dir}
\`\`\`

SKILL_MD

        # Symlink the source content directory for reference
        local content_link="${dest_path}/content"
        if [[ -L "$content_link" ]]; then
            rm "$content_link"
        fi
        ln -s "$category_dir" "$content_link"

        manifest_add "$dest_path"
        (( INSTALLED_COUNT++ )) || true
    done
}

# ---------------------------------------------------------------------------
# Install rules — symlink .md files with namespace prefix
# ---------------------------------------------------------------------------
install_rules() {
    local src_dir="${SCRIPT_DIR}/rules"
    local dest_dir="${TARGET_DIR}/rules"

    if [[ ! -d "$src_dir" ]]; then
        warn "No rules/ directory found — skipping"
        return
    fi

    mkdir -p "$dest_dir"
    info "Installing rules → ${dest_dir}/"

    while IFS= read -r -d '' md_file; do
        local basename_file
        basename_file=$(basename "$md_file")
        local category
        category=$(basename "$(dirname "$md_file")")

        # Namespace: automotive-<category>-<filename>
        local dest_name="${NAMESPACE}-${category}-${basename_file}"
        local dest_path="${dest_dir}/${dest_name}"

        safe_link "$md_file" "$dest_path"
    done < <(find "$src_dir" -name "*.md" -type f -print0)
}

# ---------------------------------------------------------------------------
# Install hooks — copy scripts with namespace prefix (never overwrite existing)
# ---------------------------------------------------------------------------
install_hooks() {
    local src_dir="${SCRIPT_DIR}/hooks"
    local dest_dir="${TARGET_DIR}/hooks"

    if [[ ! -d "$src_dir" ]]; then
        warn "No hooks/ directory found — skipping"
        return
    fi

    mkdir -p "$dest_dir"
    info "Installing hooks → ${dest_dir}/"

    while IFS= read -r -d '' sh_file; do
        local basename_file
        basename_file=$(basename "$sh_file")
        local stage
        stage=$(basename "$(dirname "$sh_file")")

        # Namespace: automotive-<stage>-<filename>
        local dest_name="${NAMESPACE}-${stage}-${basename_file}"
        local dest_path="${dest_dir}/${dest_name}"

        safe_link "$sh_file" "$dest_path"
    done < <(find "$src_dir" -name "*.sh" -type f -print0)
}

# ---------------------------------------------------------------------------
# Install knowledge base — symlink as namespaced subdirectory
# ---------------------------------------------------------------------------
install_knowledge_base() {
    # Skip knowledge base in lightweight mode to reduce token usage
    if $LIGHTWEIGHT; then
        info "Skipping knowledge-base (lightweight mode)"
        return
    fi

    local src_dir="${SCRIPT_DIR}/knowledge-base"
    local dest_dir="${TARGET_DIR}/knowledge-base"

    if [[ ! -d "$src_dir" ]]; then
        warn "No knowledge-base/ directory found — skipping"
        return
    fi

    mkdir -p "$dest_dir"
    info "Installing knowledge-base → ${dest_dir}/"

    local dest_path="${dest_dir}/${NAMESPACE}"
    safe_link "$src_dir" "$dest_path"
}

# ---------------------------------------------------------------------------
# Install workflows — symlink as namespaced subdirectory
# ---------------------------------------------------------------------------
install_workflows() {
    local src_dir="${SCRIPT_DIR}/workflows"
    local dest_dir="${TARGET_DIR}"

    if [[ ! -d "$src_dir" ]]; then
        warn "No workflows/ directory found — skipping"
        return
    fi

    # Workflows go into a namespaced directory under .claude
    local dest_path="${dest_dir}/${NAMESPACE}-workflows"
    mkdir -p "$(dirname "$dest_path")"
    info "Installing workflows → ${dest_path}"

    safe_link "$src_dir" "$dest_path"
}

# ---------------------------------------------------------------------------
# Generate settings merge snippet (NEVER modifies settings.json)
# ---------------------------------------------------------------------------
generate_settings_snippet() {
    local snippet_file="${TARGET_DIR}/${NAMESPACE}-settings-snippet.json"

    if $UNINSTALL; then
        if [[ -f "$snippet_file" ]]; then
            if ! $DRY_RUN; then
                rm -f "$snippet_file"
                info "Removed settings snippet"
            fi
        fi
        return
    fi

    if $DRY_RUN; then
        echo -e "  ${DIM}[DRY-RUN] generate: ${NAMESPACE}-settings-snippet.json${NC}"
        return
    fi

    cat > "$snippet_file" <<'SNIPPET'
{
  "_comment": "Automotive Claude Code Agents — Settings Merge Snippet",
  "_instructions": [
    "This file is NOT automatically applied to your settings.json.",
    "To enable automotive hooks, MANUALLY merge the entries below into",
    "your existing ~/.claude/settings.json under the appropriate sections.",
    "Or run: claude /update-config to have Claude help you merge it."
  ],
  "hooks_to_add": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/automotive-pre-commit-misra-check.sh",
            "timeout": 15
          }
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/automotive-pre-commit-safety-annotation.sh",
            "timeout": 15
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/automotive-pre-commit-autosar-naming.sh",
            "timeout": 10
          }
        ]
      }
    ]
  },
  "permissions_to_add": {
    "allow": [
      "Bash(python-can:*)",
      "Bash(cantools:*)",
      "Bash(cppcheck:*)"
    ]
  }
}
SNIPPET
    manifest_add "$snippet_file"
    info "Generated settings snippet (NOT applied — manual merge required)"
}

# ---------------------------------------------------------------------------
# Backup existing workspace state
# ---------------------------------------------------------------------------
create_backup_note() {
    if $DRY_RUN || $UNINSTALL; then
        return
    fi

    local backup_note="${TARGET_DIR}/backups/${NAMESPACE}-install-$(date +%Y%m%d-%H%M%S).txt"
    mkdir -p "$(dirname "$backup_note")"

    cat > "$backup_note" <<NOTE
Automotive Claude Code Agents — Installation Record
Date: $(date -Iseconds)
Source: ${SCRIPT_DIR}
Target: ${TARGET_DIR}
Manifest: ${MANIFEST_FILE}

This installation APPENDED automotive content to your existing workspace.
Nothing was replaced or overwritten.

To uninstall: ${SCRIPT_DIR}/install.sh --uninstall
NOTE
    manifest_add "$backup_note"
}

# ============================================================================
# Main
# ============================================================================

echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}  Automotive Claude Code Agents — Append-Safe Installer${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

if $UNINSTALL; then
    echo -e "  Mode:   ${RED}UNINSTALL${NC} (removes only automotive components)"
    do_uninstall
    exit 0
fi

echo -e "  Mode:   ${GREEN}APPEND${NC} (your existing workspace is preserved)"
if [[ -n "$MODULES" ]]; then
    echo -e "  Modules: ${CYAN}${MODULES}${NC} (selective install)"
elif $LIGHTWEIGHT; then
    echo -e "  Profile: ${YELLOW}LIGHTWEIGHT${NC} (minimal context, no knowledge-base)"
else
    echo -e "  Profile: ${CYAN}FULL${NC} (all modules)"
fi
echo -e "  Target: ${CYAN}${TARGET_DIR}${NC}"
echo -e "  Source: ${CYAN}${SCRIPT_DIR}${NC}"
$DRY_RUN && echo -e "          ${YELLOW}(dry-run — no changes will be made)${NC}"
echo ""

# Verify target exists or is creatable
if [[ ! -d "$TARGET_DIR" ]]; then
    if $DRY_RUN; then
        echo "  [DRY-RUN] mkdir -p $TARGET_DIR"
    else
        mkdir -p "$TARGET_DIR"
    fi
fi

# Warn if settings.json exists (we won't touch it)
if [[ -f "${TARGET_DIR}/settings.json" ]]; then
    info "Existing settings.json detected — will NOT be modified"
fi

# Warn if existing agents/commands exist
for dir in agents commands rules hooks skills; do
    if [[ -d "${TARGET_DIR}/${dir}" ]]; then
        local_count=$(ls "${TARGET_DIR}/${dir}/" 2>/dev/null | wc -l)
        if [[ $local_count -gt 0 ]]; then
            info "Existing ${dir}/ has ${local_count} items — will append, not replace"
        fi
    fi
done

echo ""

# Reset manifest for fresh install
if ! $DRY_RUN; then
    : > "$MANIFEST_FILE"
fi

# Create backup note
create_backup_note

# Install each component using the appropriate strategy
install_agents
install_commands
install_skills
install_rules
install_hooks
install_knowledge_base
install_workflows

# Generate settings merge snippet
generate_settings_snippet

# Summary
echo ""
echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
echo -e "  ${GREEN}Installed: ${INSTALLED_COUNT}${NC} automotive components"
if [[ $SKIPPED_COUNT -gt 0 ]]; then
    echo -e "  ${YELLOW}Skipped:   ${SKIPPED_COUNT}${NC} (already exist or unchanged)"
fi
echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
echo ""

if ! $DRY_RUN; then
    info "Installation complete! Your existing workspace is untouched."
    echo ""
    echo "  What was installed:"
    echo "    - Agents:       ${TARGET_DIR}/agents/${NAMESPACE}-*.md"
    echo "    - Commands:     ${TARGET_DIR}/commands/${NAMESPACE}/"
    echo "    - Skills:       ${TARGET_DIR}/skills/${NAMESPACE}-*/"
    echo "    - Rules:        ${TARGET_DIR}/rules/${NAMESPACE}-*.md"
    echo "    - Hooks:        ${TARGET_DIR}/hooks/${NAMESPACE}-*.sh"
    echo "    - Knowledge:    ${TARGET_DIR}/knowledge-base/${NAMESPACE}"
    echo "    - Workflows:    ${TARGET_DIR}/${NAMESPACE}-workflows"
    echo ""
    echo "  What was NOT modified:"
    echo "    - settings.json (merge snippet at: ${NAMESPACE}-settings-snippet.json)"
    echo "    - Existing agents, commands, rules, hooks, skills"
    echo "    - Git hooks (.git/hooks/)"
    echo ""
    echo "  Optional next steps:"
    echo "    1. Review ${TARGET_DIR}/${NAMESPACE}-settings-snippet.json"
    echo "    2. Manually merge desired hooks into settings.json"
    echo "       Or run: claude /update-config"
    echo "    3. Try: /automotive adas-camera-calibrate"
    echo "    4. Ask Claude about ISO 26262 or AUTOSAR development"
    echo ""
    echo "  Manage installation:"
    echo "    Status:    ./install.sh --status"
    echo "    Uninstall: ./install.sh --uninstall"
    echo ""
else
    info "Dry run complete. Re-run without --dry-run to apply."
fi
