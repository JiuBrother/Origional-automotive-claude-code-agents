# Automotive Claude Code Agents

Automotive software development extension for Claude Code. Appends to your existing ~/.claude workspace without replacing anything.

## Installation (Append-Safe)

```bash
# Preview what will be installed (no changes made)
./install.sh --dry-run

# RECOMMENDED: Project-specific install (isolates context, zero token overhead)
./install.sh --project /path/to/your/project --modules adas,safety

# Modular install (only selected domains)
./install.sh --modules adas,battery,diagnostics

# Lightweight install (minimal context, no knowledge-base)
./install.sh --lightweight

# Full global install (⚠️ high token usage for all conversations)
./install.sh

# Check what's installed
./install.sh --status

# Clean removal of only automotive components
./install.sh --uninstall
```

**Token Optimization:**
- `--project` installs to project-specific `.claude/` (RECOMMENDED - zero token overhead for non-automotive work)
- `--modules` installs only specified domains (e.g., `adas,battery,safety`)
- `--lightweight` skips heavy knowledge-base (~60-70% token reduction)
- Global install loads ALL content into EVERY conversation (not recommended)

See [Token Optimization Guide](docs/TOKEN_OPTIMIZATION.md) for details.

**Safety guarantees:**
- Your settings.json is NEVER modified
- Your existing agents, commands, rules, hooks, skills are NEVER touched
- All automotive content uses `automotive-` prefix to avoid collisions
- A manifest tracks exactly what was installed for clean uninstall

After install, optionally merge hooks from `automotive-settings-snippet.json` into your settings.json.

## Project Structure

```
skills/           -- Automotive domain skills (ADAS, battery, AUTOSAR, safety...)
agents/           -- Specialized agent definitions (YAML)
commands/         -- Automation scripts (shell)
workflows/        -- End-to-end development workflows (YAML)
rules/            -- Coding, safety, and security standard rules
hooks/            -- Git lifecycle hooks (pre-commit, pre-push)
knowledge-base/   -- Standards reference (AUTOSAR, ISO 26262, ASPICE)
tools/            -- Tool routing, adapters, LLM council (Python)
examples/         -- Example projects with production code
tests/            -- Unit, integration, and E2E test suites
docs/             -- Getting started, architecture guides
```

## Key Domains

- **ADAS/Autonomous**: Sensor fusion, perception, planning, control (L0-L5)
- **AUTOSAR**: Classic (C) and Adaptive (C++) platform development
- **Functional Safety**: ISO 26262 lifecycle, HARA, FMEA, FTA, ASIL
- **Cybersecurity**: ISO 21434, TARA, secure boot, PKI, IDS
- **Battery/EV**: BMS algorithms, thermal management, charging
- **Diagnostics**: UDS (ISO 14229), OBD-II, DoIP, flash programming
- **V2X**: DSRC, C-V2X, cooperative awareness, platooning
- **Powertrain/Chassis**: ECM, TCM, ESC, EPS, ABS control
- **SDV Platform**: OTA updates, digital twins, containerized apps
- **HPC**: Hypervisors, AUTOSAR Adaptive, central compute
- **Zonal Architecture**: Automotive Ethernet, SOME/IP, zone controllers
- **Cloud**: AWS IoT, Azure Digital Twins, GCP, fleet management

## Standards Covered

ISO 26262, ISO 21434, ISO 21448 (SOTIF), AUTOSAR Classic/Adaptive,
ASPICE, MISRA C/C++, SAE J1979, IEEE 802.11p, 3GPP C-V2X, CAN/LIN/FlexRay

## Build & Test

```bash
pytest tests/ -v
python -m pytest tests/test_skills.py
python -m pytest tests/test_agents.py
ruff check tools/ scripts/
```

## How It Integrates

After `./install.sh`, your ~/.claude workspace gets:

| What | Where | Format |
|------|-------|--------|
| Agents | `~/.claude/agents/automotive-*.md` | Claude Code .md frontmatter |
| Commands | `~/.claude/commands/automotive/` | Slash commands via `/automotive` |
| Skills | `~/.claude/skills/automotive-*/` | SKILL.md + content symlinks |
| Rules | `~/.claude/rules/automotive-*.md` | Symlinks to rule .md files |
| Hooks | `~/.claude/hooks/automotive-*.sh` | Symlinks to hook scripts |
| Knowledge | `~/.claude/knowledge-base/automotive` | Symlink to KB directory |
| Workflows | `~/.claude/automotive-workflows` | Symlink to workflows |

Your existing content is never modified. Everything automotive-prefixed.
