# Node.js Upgrade on ARM64 — Session Notes

**Date:** 2026-06-10  
**Context:** Hermes update required Node.js v24+, current was v22.22.3  
**Environment:** ARM64 (aarch64) Raspberry Pi, Linux 6.8.0-1057-raspi  

## Original State

| Item | Value |
|------|-------|
| Node.js | v22.22.3 |
| npm | 10.9.8 |
| Node path | `/home/qn/.hermes/node/bin/node` (Hermes-bundled) |
| Symlink | `~/.local/bin/node` → `~/.hermes/node/bin/node` |
| Arch | aarch64 |

## Target

Node.js v24.x (latest v24.x), npm 11.x. At time of writing: v24.16.0, npm 11.13.0. Always check the actual latest before downloading.

## Hermes Node Directory Structure

```
~/.hermes/node/
├── bin/
│   ├── node          # ELF binary (122MB on v22, 121MB on v24)
│   ├── npm           → ../lib/node_modules/npm/bin/npm-cli.js
│   ├── npx           → ../lib/node_modules/npm/bin/npx-cli.js
│   ├── corepack      → ../lib/node_modules/corepack/dist/corepack.js
│   └── agent-browser → /home/qn/.hermes/hermes-agent/node_modules/agent-browser/bin/agent-browser-linux-arm64
├── include/
├── lib/
├── share/
├── CHANGELOG.md
├── LICENSE
└── README.md
```

The `agent-browser` symlink is Hermes-specific and must be recreated after Node replacement.

## URLs

- Latest v24.x index: `https://nodejs.org/dist/latest-v24.x/`
- ARM64 binary: `https://nodejs.org/dist/latest-v24.x/node-v{VERSION}-linux-arm64.tar.xz`

## Verification Commands

```bash
node --version
npm --version
node -e "console.log('Node v' + process.version + ' on ' + process.arch)"
```
