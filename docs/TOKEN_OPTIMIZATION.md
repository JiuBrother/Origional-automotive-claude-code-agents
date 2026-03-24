# Token Usage Optimization Guide

## Problem

Installing automotive-claude-code-agents globally into `~/.claude` loads **all** automotive content (agents, skills, rules, knowledge base) into the context window for **every** conversation, even non-automotive work. This causes:

- **High token consumption** (10k+ tokens per prompt)
- **Increased API costs**
- **Slower responses** (larger context to process)
- **Context pollution** for non-automotive projects

## Solutions

### 1. Project-Specific Installation (RECOMMENDED)

Install automotive components only into project-specific `.claude/` directories:

```bash
# Navigate to your automotive project
cd ~/projects/my-adas-project

# Install to project-specific workspace
./automotive-claude-code-agents/install.sh --project .
```

**Benefits:**
- ✅ Automotive context only loads when working in automotive projects
- ✅ Zero token overhead for non-automotive work
- ✅ Clean separation of concerns
- ✅ Multiple automotive projects can have different module sets

### 2. Modular Installation

Install only the domains you actually use:

```bash
# ADAS development only
./install.sh --modules adas,autosar

# Battery + diagnostics only
./install.sh --modules battery,diagnostics --project ~/bms-project

# Full list of available modules
./install.sh --help
```

**Available Modules:**
- `adas` - ADAS/autonomous driving
- `autosar` - AUTOSAR Classic & Adaptive
- `battery` - Battery management systems
- `cybersecurity` - ISO 21434, security
- `diagnostics` - UDS, OBD-II, DoIP
- `functional-safety` - ISO 26262, ASIL
- `powertrain` - Engine/transmission control
- `v2x` - Vehicle-to-everything communication
- `cloud-native` - Cloud and IoT
- `sdv` - Software-defined vehicle
- `ecu-systems` - ECU development
- `hpc` - High-performance computing
- `zonal` - Zonal architecture
- `emerging-tech` - Emerging technologies
- `manufacturing` - Industry 4.0/5.0

### 3. Lightweight Mode

Minimal installation without heavy knowledge base:

```bash
# Lightweight install
./install.sh --lightweight

# Or combine with project-specific
./install.sh --lightweight --project ~/my-project
```

**What's excluded in lightweight mode:**
- ❌ Knowledge base (115 documents, ~500KB markdown)
- ✅ Essential agents, commands, skills (compact)

**Token savings:** ~60-70% reduction

### 4. Hybrid Approach (Best for Teams)

```bash
# Developer workstation: project-specific with needed modules
cd ~/automotive-projects/adas-system
./install.sh --project . --modules adas,functional-safety,autosar

# CI/CD environment: lightweight install
./install.sh --lightweight --project /workspace

# Research/exploration: full install in dedicated workspace
mkdir ~/automotive-workspace && cd ~/automotive-workspace
./install.sh --project .
```

## Token Impact Comparison

| Installation Type | Approx. Tokens | Use Case |
|------------------|----------------|----------|
| Global Full | 12,000-15,000 | ❌ Not recommended |
| Global Lightweight | 4,000-6,000 | ⚠️ Occasional automotive work |
| Global Modular (2-3 modules) | 6,000-8,000 | ⚠️ Specific domains only |
| Project-Specific Full | 0 (when not in project) | ✅ Dedicated automotive projects |
| Project-Specific Lightweight | 0 (when not in project) | ✅ Minimal automotive needs |
| Project-Specific Modular | 0 (when not in project) | ✅ RECOMMENDED |

## Migration Guide

### Already installed globally? Here's how to migrate:

```bash
# 1. Uninstall global installation
cd ~/automotive-claude-code-agents
./install.sh --uninstall

# 2. Install project-specifically
cd ~/my-automotive-project
~/automotive-claude-code-agents/install.sh --project . --modules adas,safety

# 3. Verify
~/automotive-claude-code-agents/install.sh --status
```

### Check your current installation:

```bash
./install.sh --status
```

## Best Practices

### ✅ DO:
- Use `--project` for dedicated automotive work
- Use `--modules` to install only what you need
- Use `--lightweight` for occasional automotive tasks
- Create separate project workspaces for different automotive domains
- Review installed components with `--status`

### ❌ DON'T:
- Install full suite globally in `~/.claude` (high token cost)
- Install all modules if you only use 1-2 domains
- Keep unused knowledge base loaded in context
- Mix automotive and non-automotive work in same workspace

## FAQ

**Q: Can I switch from global to project-specific without losing settings?**

A: Yes. The installer generates `automotive-settings-snippet.json` which you can copy to project-specific `.claude/settings.json`.

**Q: What if I need different modules for different projects?**

A: Install separately in each project directory:
```bash
cd ~/project-a && ./install.sh --project . --modules adas
cd ~/project-b && ./install.sh --project . --modules battery
```

**Q: Can I add more modules later?**

A: Yes. Re-run the installer with the complete list of desired modules:
```bash
./install.sh --project . --modules adas,battery,diagnostics
```
The installer is append-safe and won't duplicate content.

**Q: How do I know which modules I need?**

A: Use `--dry-run` to preview:
```bash
./install.sh --dry-run --modules adas
./install.sh --dry-run --lightweight
```

## Monitoring Token Usage

Track your actual token usage:

1. Check Claude Code conversation history for token counts
2. Compare before/after installation
3. Use `--dry-run` to preview component count before installing

## Future Optimizations (Roadmap)

- [ ] RAG integration (dynamic loading of knowledge base)
- [ ] Context compression for markdown files
- [ ] Lazy-loading of large skill libraries
- [ ] Token usage dashboard
- [ ] Automatic module recommendation based on codebase analysis

## Support

If you experience high token usage:

1. Check installation mode: `./install.sh --status`
2. Review [Issue #2](https://github.com/theja0473/automotive-claude-code-agents/issues/2)
3. Consider migrating to project-specific installation
4. Report token usage patterns to help us improve

---

**Remember:** The right installation strategy depends on your workflow. When in doubt, use project-specific installation with selective modules.
