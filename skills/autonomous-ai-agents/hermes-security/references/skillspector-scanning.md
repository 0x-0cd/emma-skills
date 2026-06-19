# NVIDIA SkillSpector — Installation & Scanning Notes

## Environment-Specific Workarounds (Raspberry Pi / ARM64)

### Proxy Setup
SkillSpector's build (grpcio, yara-python) needs network access. On Pi with clash VPN:

```bash
# Git clone needs explicit proxy
git clone -c http.proxy=http://127.0.0.1:7890 -c https.proxy=http://127.0.0.1:7890 \
  https://github.com/NVIDIA/SkillSpector.git

# uv sync needs proxy env vars (doesn't inherit git proxy)
HTTP_PROXY=http://127.0.0.1:7890 HTTPS_PROXY=http://127.0.0.1:7890 uv sync
```

### Python 3.12+ Requirement
The package requires Python ≥3.12. On Pi with python3-venv missing:

```bash
# Instead of python3.12 -m venv (fails without ensurepip):
uv venv --python 3.12 --seed .venv
```

### Binary Dependencies
Downloads grpcio, cryptography, yara-python, zstandard as native wheels. ARM64 wheels are available for all of these — no compilation needed.

## Scanning Commands

```bash
# Single skill directory (fast)
skillspector scan ./my-skill/ --no-llm

# JSON output for programmatic use
skillspector scan ./my-skill/ --format json --output report.json

# Full skills tree (warning: slow on large directories, 240s+ for ~50 skills)
# Scan individual skills instead of the whole tree
```

## Score Interpretation Quick Reference

| Score | Severity | Action |
|-------|----------|--------|
| 0 | LOW | Clean — no issues |
| 5–20 | LOW | Minor advisory items (license scope, doc patterns) |
| 21–50 | MEDIUM | Caution — review flagged issues |
| 51–80 | HIGH | Don't install without understanding findings |
| 81–100 | CRITICAL | Likely malicious or deeply unsafe |

## Known False Positive Patterns (Markdown Skills)

Found during initial scan of 20 Hermes skills:

- **E1 (External Transmission)** on API URLs: `https://api.github.com`, `https://api.openai.com` in SKILL.md docs
- **PE3 (Credential Access)** on config paths: `~/.config/gh/hosts.yml`, `~/.ssh/config` as documentation examples
- **SC2 (External Script Fetching)** on curl/wget doc examples
- **RA2 (Session Persistence)** on skills describing `cron`/`background`/`long-running` without actual cron install
- **EA3 (Scope Creep)** found in LICENSE files due to broad legal language
- **LP3 (No Permissions Declared)** — skills without a `permissions` field in SKILL.md frontmatter

## Initial Hermes Skills Scan Results (2026-06-12)

20 skills scanned, `--no-llm` (static analysis only):

### 🔴 CRITICAL (100/100)
- **godmode** (red-teaming/jailbreak) — 24 issues: exec/compile chains, taint flows, credential leakage, instruction override. **Expected** — it's designed for jailbreaking.
- **github-code-review** — 23 issues: 15× E1 (API URLs), 3× PE3 (config paths), 5× SC2 (curl examples). **False positives** — all from markdown docs, no executable code.

### 🟠 HIGH (60/100)
- **himalaya (email)** — 3 issues: PE3 credential access (config paths in docs), RA2 session persistence. **Mostly false positives** — documented config paths, not hardcoded secrets.

### 🟡 MEDIUM (25/100)
- **blogwatcher** — 4 issues: EA2 autonomous decisions, TM1 tool parameter abuse. **Legitimate advisory** — skill gives the agent broad autonomy to manage feeds.

### 🟢 LOW (0–20/100)
All other skills (auto-format, TDD, plan, spike, systematic-debugging, sketch, obsidian, etc.) — **0/100, clean**.

**Takeaway:** Pure markdown skills score 0. Skills with real code get flagged proportionally. The two 100/100 scores were either intentional (godmode) or pure doc-string noise (github-code-review).
