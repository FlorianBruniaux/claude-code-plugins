# security-suite

Security auditing pipeline for Claude Code — OWASP vulnerability scanning, multi-agent cyber defense, threat detection, and 13 protective hooks.

## What's included

**Agents (7)**: security-auditor, security-patcher, anomaly-detector, log-ingestor, risk-classifier, threat-reporter, cyber-defense pipeline (4-stage)

**Commands (5)**: `/security`, `/security-audit`, `/security-check`, `/update-threat-db`, `/sandbox-status`

**Skills (3)**: cyber-defense-team, security-checklist, eval-rules

**Hooks (13)**: secrets scanner, prompt injection detector, dangerous actions blocker, sandbox validation, MCP config integrity, repo integrity scanner, security gate, and more

## Install

```bash
claude plugin install github:FlorianBruniaux/claude-code-plugins/plugins/security-suite
```

## Quick start

```
/security-audit          # Full scored security audit (2-5 min)
/security-check          # Quick scan against threat DB (~30s)
/security                # OWASP Top 10 rapid assessment
```
