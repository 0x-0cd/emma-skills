# ARM64 / Raspberry Pi Setup Notes

## System

- OS: Ubuntu Noble (24.04) or Debian Bookworm
- Arch: aarch64 (ARM64)
- User: standard user (no docker group, no sudo for pip)
- Python: 3.12 system-wide (PEP 668 — must use venv)

## Dependencies

```bash
# python3-venv is NOT pre-installed on Ubuntu minimal
sudo apt install -y python3.12-venv
```

## Virtual Environment

```bash
cd ~/MediaCrawler
python3 -m venv .venv
source .venv/bin/activate
```

After activation, pip works normally inside the venv.

## Pip mirror (China)

Use Tsinghua mirror for faster downloads:
```bash
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt
```

All packages in MediaCrawler's requirements.txt have pre-built ARM64 wheels on Tsinghua mirror — no compilation needed on Pi.

## Playwright Chromium

```bash
# Download (~167MB for ARM64):
playwright install chromium

# This downloads from azureedge.net — needs proxy in China
```

Install location: `~/.cache/ms-playwright/chromium-1124/`

## Memory profile

| Scenario | RAM usage | Available on 4GB Pi |
|----------|-----------|-------------------|
| Idle system | ~1.5GB | 2.2GB free |
| + Python + Chromium (headless crawl) | ~+400MB | ~1.8GB free |
| + Two concurrent crawls | ~+700MB | ~1.5GB free |

Single-platform crawling is comfortable. Note: swap is usually 0 on Pi — memory spikes can cause OOM.

## No desktop display

- `HEADLESS = True` — Chromium runs headless
- `LOGIN_TYPE = "cookie"` — no QR code scanner available
- `ENABLE_CDP_MODE = False` — no existing browser to connect to
