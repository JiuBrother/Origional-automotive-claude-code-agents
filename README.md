<p align="center">
  <img src="docs/assets/banner.png" alt="Automotive Claude Code Agents" width="800" />
</p>

<h1 align="center">Automotive Claude Code Agents</h1>

<p align="center">
  <strong>The automotive engineer's AI-powered command center for Claude Code</strong>
</p>

<p align="center">
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT" /></a>
  <a href="https://github.com/anthropics/claude-code"><img src="https://img.shields.io/badge/Built%20for-Claude%20Code-7C3AED" alt="Built for Claude Code" /></a>
  <a href="#domains-covered"><img src="https://img.shields.io/badge/Domains-14+-green" alt="14+ Domains" /></a>
  <a href="#whats-inside"><img src="https://img.shields.io/badge/Skills-75+-orange" alt="75+ Skills" /></a>
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/PRs-Welcome-brightgreen" alt="PRs Welcome" /></a>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> |
  <a href="#why-this-exists">Why This Exists</a> |
  <a href="#whats-inside">What's Inside</a> |
  <a href="#domains-covered">Domains</a> |
  <a href="CONTRIBUTING.md">Contributing</a>
</p>

---

## Why This Exists

Automotive software engineering is one of the most complex and regulated domains in the world. Engineers juggle **ISO 26262 functional safety**, **AUTOSAR architectures**, **MISRA compliance**, **cybersecurity standards**, and **real-time embedded constraints** -- all while shipping on aggressive timelines.

**Automotive Claude Code Agents** turns Claude Code into a domain-expert copilot that understands the automotive stack from silicon to cloud. Instead of spending hours looking up ASIL decomposition rules or AUTOSAR naming conventions, you get instant, standards-compliant guidance woven directly into your development workflow.

One install. Zero config. Your existing workspace stays untouched.

```
Before:  "How do I structure an FMEA for this BMS module?" -> 2 hours of research
After:   claude "Generate FMEA for overcurrent protection in ASIL-D BMS" -> 2 minutes
```

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/theja0473/automotive-claude-code-agents.git
cd automotive-claude-code-agents

# 2. Preview what will be installed (no changes made)
./install.sh --dry-run

# 3. RECOMMENDED: Install to your automotive project (avoids token overhead)
./install.sh --project ~/my-automotive-project --modules adas,safety

# OR: Install globally with selective modules
./install.sh --modules adas,battery

# OR: Lightweight install (minimal context)
./install.sh --lightweight

# 4. Start using it immediately
claude "Help me design an AUTOSAR Adaptive service for camera fusion"
```

**⚠️ Token Usage Note:** Global installation (`~/.claude`) loads all content into context for every conversation. For best performance, use `--project` for automotive work or `--modules` to install only needed domains. See [Token Optimization Guide](docs/TOKEN_OPTIMIZATION.md).

```bash
# Check what's installed
./install.sh --status

# Clean removal (only removes automotive components)
./install.sh --uninstall
```

### Verify Installation

```bash
# Use an automotive agent
claude "Using automotive-adas-perception-engineer, design a LiDAR point cloud pipeline"

# Run an automotive command
/automotive adas-camera-calibrate

# Get safety guidance
claude "Review this C function for ISO 26262 ASIL-D compliance"

# Generate AUTOSAR artifacts
/automotive autosar-swc-scaffold
```

---

## What's Inside

| Component | Count | Location (`~/.claude/`) | Description |
|-----------|------:|------------------------|-------------|
| **Skills** | 75+ categories | `skills/automotive-*/` | Deep domain knowledge with implementation patterns |
| **Agents** | 39 | `agents/automotive-*.md` | Specialized AI personas (safety engineer, ADAS architect...) |
| **Commands** | 33 | `commands/automotive/` | One-shot slash commands (`/automotive <cmd>`) |
| **Workflows** | 26 | `automotive-workflows/` | End-to-end development processes |
| **Rules** | 31 | `rules/automotive-*.md` | MISRA, AUTOSAR, ISO 26262 coding standards |
| **Hooks** | 24 | `hooks/automotive-*.sh` | Pre-commit safety and quality gates |
| **Knowledge Base** | 115 docs | `knowledge-base/automotive/` | Standards reference library |

### How It Integrates

```
Your Existing Workspace          +  Automotive Extension
~/.claude/                       |
  settings.json     (untouched)  |
  agents/my-agent.md (untouched) |  agents/automotive-adas-*.md  (added)
  rules/my-rules.md  (untouched) |  rules/automotive-misra-*.md  (added)
  commands/my-cmd/   (untouched) |  commands/automotive/          (added)
```

---

## Domains Covered

| Domain | What You Get |
|--------|-------------|
| **ADAS / Autonomous Driving** | Sensor fusion, perception pipelines, path planning, L0-L5 control |
| **AUTOSAR Classic & Adaptive** | SWC scaffolding, RTE generation, BSW config, ara::com patterns |
| **Functional Safety (ISO 26262)** | HARA templates, FMEA/FTA generation, ASIL decomposition, safety cases |
| **Cybersecurity (ISO 21434)** | TARA analysis, secure boot chains, PKI setup, IDS rules |
| **Battery & EV Systems** | BMS algorithms, SOC/SOH estimation, thermal management, charging protocols |
| **Diagnostics** | UDS service implementation, DTC management, DoIP, flash sequences |
| **V2X Communication** | DSRC/C-V2X stacks, cooperative awareness, platooning protocols |
| **Powertrain & Chassis** | Engine/transmission control, ESC, EPS, ABS algorithms |
| **SDV Platform** | OTA update pipelines, digital twins, containerized vehicle apps |
| **HPC / Central Compute** | Hypervisor config, AUTOSAR Adaptive services, GPU compute |
| **Zonal Architecture** | Automotive Ethernet TSN, SOME/IP, zone controller design |
| **Cloud & Fleet** | AWS IoT, Azure Digital Twins, fleet analytics, telemetry pipelines |
| **Manufacturing** | Industry 4.0/5.0, factory digital twins, quality systems |
| **Emerging Tech** | Hydrogen fuel cells, quantum computing readiness, UAM/eVTOL |

### Standards Coverage

| Standard | Coverage | What It Provides |
|----------|----------|-----------------|
| ISO 26262 (Functional Safety) | Full lifecycle | ASIL classification, code rules, verification templates |
| ISO 21434 (Cybersecurity) | Full lifecycle | TARA methodology, secure coding, incident response |
| ISO 21448 (SOTIF) | Sensor/perception | Triggering conditions, ODD definition, validation |
| AUTOSAR Classic R22-11 | BSW + RTE | Module naming, API patterns, configuration |
| AUTOSAR Adaptive R22-11 | ara::* APIs | Service design, error handling, execution management |
| MISRA C:2012 | All rules | Violation detection, deviation templates, CI gates |
| MISRA C++:2023 | Key rules | Modern C++ safety subset, ASIL-specific restrictions |
| ASPICE v3.1 | SWE.1-6 | Process templates, work products, traceability |

---

## Project Structure

```
automotive-claude-code-agents/
  skills/              75+ domain skill categories (YAML + Markdown)
  agents/              39 specialized AI agent definitions
  commands/            33 automation slash commands
  workflows/           26 end-to-end development workflows
  rules/               Coding, safety, and security standard rules
  hooks/               Git lifecycle hooks (safety gates, secret scan)
  knowledge-base/      115 standards reference documents
  tools/               Tool routing, adapters, LLM council (Python)
  examples/            Example projects with production code
  tests/               Unit, integration, and E2E test suites
  docs/                Architecture guides and tutorials
  install.sh           Append-safe installer (the only file you run)
```

---

## Optional: Settings Integration

The installer generates `~/.claude/automotive-settings-snippet.json` with recommended hooks for MISRA checking, safety review prompts, and secret scanning. To activate:

```bash
# Option 1: Let Claude merge it for you
claude "Merge automotive-settings-snippet.json into my settings.json"

# Option 2: Review and manually copy desired hooks
cat ~/.claude/automotive-settings-snippet.json
```

This step is entirely optional. All skills, agents, and commands work without it.

---

## Build & Test

```bash
# Run all tests
pytest tests/ -v

# Lint Python code
ruff check tools/ scripts/

# Generate coverage report
pytest --cov=tools --cov-report=html tests/

# Validate skill/agent YAML structure
python -m pytest tests/test_skills.py tests/test_agents.py
```

---

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the full development plan. Highlights:

- [ ] Simulink/MATLAB model integration skills
- [ ] CARLA/LGSVL simulation workflows
- [ ] Hardware-in-the-Loop (HIL) test orchestration
- [ ] Multi-language support (German, Japanese, Korean, Chinese)
- [ ] VS Code extension for visual skill browsing

---

## Contributing

We welcome contributions from automotive engineers, safety experts, and AI enthusiasts. See [CONTRIBUTING.md](CONTRIBUTING.md) for:

- How to add new skills, agents, or commands
- Code quality and testing standards
- The pull request process
- Commit message conventions

---

## Community

- **Issues**: [Report bugs or request features](../../issues)
- **Discussions**: [Ask questions and share use cases](../../discussions)
- **Security**: See [SECURITY.md](SECURITY.md) for vulnerability reporting

---

## License

[MIT License](LICENSE) -- free for commercial and personal use.

Copyright (c) 2026 Automotive Claude Code Contributors

---

<p align="center">
  <sub>Built with care for the automotive engineering community.</sub><br/>
  <sub>If this project helps your work, consider giving it a star.</sub>
</p>
