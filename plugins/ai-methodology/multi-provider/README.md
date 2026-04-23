---
title: "Multi-Provider Setup for Claude Code"
description: "Copilot bridge enabling 25+ AI models via GitHub Copilot Pro+ subscription"
tags: [integration, ai-ecosystem, config]
---

# Multi-Provider Setup for Claude Code

> 🔗 **This content has been moved to a dedicated repository**

## 📦 cc-copilot-bridge

A Copilot bridge for Claude Code CLI that enables flat-rate access to 25+ AI models using your existing GitHub Copilot Pro+ subscription.

**Repository**: [github.com/FlorianBruniaux/cc-copilot-bridge](https://github.com/FlorianBruniaux/cc-copilot-bridge)
[![Latest Release](https://img.shields.io/github/v/release/FlorianBruniaux/cc-copilot-bridge)](https://github.com/FlorianBruniaux/cc-copilot-bridge/releases)

> **Terms of Service Notice**: This tool uses the GitHub Copilot API via an unofficial proxy. This may not be officially supported by GitHub and could violate their Terms of Service in some contexts (particularly corporate environments). Review GitHub's ToS before use. Rate limits apply and vary by subscription tier.

---

## 🎯 What It Does

Extends your GitHub Copilot Pro+ subscription to work with Claude Code CLI, giving you:
- **Flat-rate access** to 25+ models (GPT-4.1, Claude Opus/Sonnet/Haiku, Gemini, etc.)
- **No per-token billing** — subject to GitHub Copilot rate limits
- **Local model support** via Ollama (100% offline, no data leaves your machine)

### Architecture

```
Claude Code CLI
     │
     ├─── localhost:4141 ──► copilot-api ──► GitHub Copilot (internet)
     │                                        OAuth token required
     ├─── localhost:11434 ─► Ollama (local, no internet traffic)
     │
     └─── api.anthropic.com (internet, per-token pricing)
```

### Features

- 🎯 **CORE**: Copilot Bridge — Flat-rate access to 25+ AI models
- 🎁 **BONUS**: Ollama Local — 100% private inference, offline capable, Apple Silicon optimized
- 🔄 **FALLBACK**: Anthropic Direct — Native API for production-critical work (manual switch)
- 🔧 **MCP Profiles System** — Model-specific config for strict validation models (GPT-4.1, Gemini)
- 🎭 **System Prompts** — Model identity injection for correct self-identification
- 📊 **Session Logging** — Audit trail of provider usage and durations (contains prompts — see Security Model)

---

## 🚀 Quick Start

### Installation

```bash
# Download the script and review it before executing (recommended)
curl -fsSL https://raw.githubusercontent.com/FlorianBruniaux/cc-copilot-bridge/main/install.sh -o /tmp/cc-bridge-install.sh
cat /tmp/cc-bridge-install.sh   # Review content
bash /tmp/cc-bridge-install.sh

# Reload shell
source ~/.zshrc  # or ~/.bashrc
```

> If you prefer, a manual installation guide is available in [QUICKSTART.md](https://github.com/FlorianBruniaux/cc-copilot-bridge/blob/main/QUICKSTART.md).

### Usage

```bash
# Check provider status
ccs

# Use Anthropic Direct (best quality)
ccd

# Use GitHub Copilot (flat-rate with subscription)
ccc

# Use Ollama Local (fully private, no internet)
cco

# Switch models dynamically
ccc-opus    # Claude Opus 4.5 (best quality)
ccc-sonnet  # Claude Sonnet 4.5 (balanced)
ccc-haiku   # Claude Haiku 4.5 (fastest)
ccc-gpt     # GPT-4.1 (alternative)
```

---

## 📚 Documentation

Complete documentation available in the repository:

- [**Quick Start Guide**](https://github.com/FlorianBruniaux/cc-copilot-bridge/blob/main/QUICKSTART.md) - 2-minute setup
- [**Commands Reference**](https://github.com/FlorianBruniaux/cc-copilot-bridge/blob/main/docs/COMMANDS.md) - All available commands
- [**Model Switching**](https://github.com/FlorianBruniaux/cc-copilot-bridge/blob/main/docs/MODEL-SWITCHING.md) - Dynamic model selection strategies
- [**MCP Profiles**](https://github.com/FlorianBruniaux/cc-copilot-bridge/blob/main/docs/MCP-PROFILES.md) - MCP compatibility system architecture
- [**Performance Optimization**](https://github.com/FlorianBruniaux/cc-copilot-bridge/blob/main/docs/OPTIMISATION-M4-PRO.md) - Apple Silicon (M1/M2/M3/M4) optimization
- [**Troubleshooting**](https://github.com/FlorianBruniaux/cc-copilot-bridge/blob/main/docs/TROUBLESHOOTING.md) - Common issues and solutions

---

## 💡 Why Use This?

### Cost Comparison

| Provider | Cost | Limits | Notes |
|----------|------|--------|-------|
| **Anthropic Direct** | Usage-based | Per-token | Official, ToS-compliant |
| **cc-copilot-bridge** | Copilot Pro+ subscription | Rate-limited by GitHub | Unofficial proxy — verify ToS |
| **Ollama Local** | Free | Hardware-bound | Data stays local |

> Note: Copilot Pro+ pricing and rate limits are set by GitHub and subject to change. Verify current pricing at [github.com/features/copilot](https://github.com/features/copilot).

### Strategic Use Cases

| Scenario | Recommended | Reasoning |
|----------|-------------|-----------|
| Production deployment | `ccd` or `ccc-opus` | Best quality, critical decisions |
| Daily development | `ccc-sonnet` | Flat-rate, fast, balanced |
| Quick questions | `ccc-haiku` | Fastest responses |
| Code review | `ccc-opus` | Maximum quality |
| Proprietary code | `cco` | No data leaves your machine |
| Learning/prototyping | `ccc` | No per-token charges |

---

## 🔗 Links

- **Repository**: [github.com/FlorianBruniaux/cc-copilot-bridge](https://github.com/FlorianBruniaux/cc-copilot-bridge)
- **Quick Start**: [QUICKSTART.md](https://github.com/FlorianBruniaux/cc-copilot-bridge/blob/main/QUICKSTART.md)
- **Full Documentation**: [docs/](https://github.com/FlorianBruniaux/cc-copilot-bridge/tree/main/docs)
- **Issues & Support**: [GitHub Issues](https://github.com/FlorianBruniaux/cc-copilot-bridge/issues)

---

## 🏗️ Architecture Details

### Providers Overview

**1. Copilot Bridge** (Core Feature)
- Uses copilot-api proxy on localhost:4141 (loopback only)
- Authenticates with GitHub OAuth
- Supports 25+ models (Claude, GPT, Gemini, Grok)
- Flat-rate subscription pricing — no per-token charges
- Subject to GitHub Copilot API rate limits

**2. Ollama Local** (Bonus Feature)
- Runs locally on localhost:11434
- No internet traffic for inference — no data leaves your machine
- Optimized for Apple Silicon (M1/M2/M3/M4)
- Supports qwen2.5-coder, deepseek, codellama families
- Free and offline capable

**3. Anthropic Direct** (Fallback)
- Native Anthropic API connection
- Best quality for production-critical work
- Per-token pricing — check [anthropic.com/pricing](https://www.anthropic.com/pricing) for current rates
- Manually activated via `ccd` (no automatic failover)

### MCP Profiles System

**Problem**: GPT-4.1 applies strict JSON Schema validation that rejects some MCP servers with incomplete schemas.

**Solution**: Dynamic profile generation with model-specific exclusions.

```
~/.claude/mcp-profiles/
├── excludes.yaml       # SOURCE OF TRUTH
├── generated/          # Auto-generated — run generate.sh after adding new MCP servers
│   ├── gpt.json       # GPT models config (excludes problematic servers)
│   └── gemini.json    # Gemini models config
└── generate.sh         # Profile generator
```

**Behavior**:
- Claude models → Use default config (all MCPs)
- GPT models → Use gpt.json (excludes incompatible servers)
- Gemini models → Use gemini.json (excludes incompatible servers)

> **Note**: This is a workaround for upstream schema compatibility issues, not a permanent fix. Remember to re-run `generate.sh` after installing new MCP servers.

---

## 🔒 Security Model

| Component | Details |
|-----------|---------|
| GitHub OAuth token | Stored by copilot-api — check [its documentation](https://github.com/FlorianBruniaux/cc-copilot-bridge) for exact path |
| Copilot proxy port | localhost:4141 (loopback only — not exposed on network interfaces) |
| Session logs | Stored locally — **contain full prompts and responses**. Review before use with proprietary code. |
| Revoking access | GitHub Settings → Applications → Authorized OAuth Apps |

---

## ⚠️ Known Limitations & Risks

- **ToS compliance**: Using Copilot via an unofficial proxy may violate GitHub's Terms of Service. Evaluate risk before use in corporate or regulated environments.
- **Rate limits**: GitHub Copilot applies API rate limits. "No per-token billing" does not mean unlimited requests.
- **No automatic failover**: If the copilot-api proxy crashes, Claude Code will fail. Switch manually to `ccd` (Anthropic Direct). No retry logic or health-check-based failover is implemented.
- **Proxy restart**: If `localhost:4141` becomes unresponsive, restart copilot-api manually. No watchdog/launchd daemon is included.
- **copilot-api dependency**: This tool depends on a third-party library. Pin your version and audit before updating.

---

## 🎓 Legacy Files

If you need the old multi-provider setup files that were previously in this guide:
- Check the git history of this repository
- Or refer to the new dedicated repository which includes all improvements

---

## 📝 Version Information

- **cc-copilot-bridge**: v1.2.0 (last synced: 2026-01-22) — [check for newer releases](https://github.com/FlorianBruniaux/cc-copilot-bridge/releases)
- **Features**: MCP Profiles + System Prompts
- **License**: MIT

---

[⬆ Back to Examples Index](../README.md)