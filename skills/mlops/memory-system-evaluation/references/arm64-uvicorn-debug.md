# ARM64 (Raspberry Pi) — uvicorn + aiohttp/httpx Debugging

## Symptom
Mneme HTTP server starts, sync clients (urllib, curl) connect fine, but async clients (aiohttp, httpx) consistently timeout. Server accepts TCP connections but never sends HTTP response headers to async clients.

## Diagnosis
1. Test sync client: `urllib.request.urlopen('http://localhost:8989/v1/stats')` — works
2. Test async client: `aiohttp.ClientSession().get(...)` — times out
3. Test raw HTTP: `exec 3<>/dev/tcp/127.0.0.1/8989; echo -e "GET / HTTP/1.1\r\nHost: ...\r\n\r\n" >&3` — times out
4. Check process: `ss -tlnp | grep 8989` shows LISTEN state with pending connections (Recv-Q > 0)

## Root Cause
Uvicorn + asyncio event loop incompatibility with ONNX Runtime thread pool on ARM64. The ONNX model loading (`EmbeddingModel()` at startup) may interfere with asyncio's event loop scheduling when async HTTP libraries connect. Exact mechanism unclear but consistently reproducible on this platform.

## Workarounds (in priority order)

### 1. Local Mode (best)
Bypass the HTTP server entirely and use Mneme's Python API directly. See `templates/run_locomo_local.py`.

### 2. `mneme serve` CLI
```bash
cd ~/projects/ai-memory-system
MNEME_DB_PATH=/tmp/mneme_bench.db .venv/bin/mneme serve --port 8989
```
Using the CLI binary (installed entry point) is more reliable than direct `uvicorn.run()`.

### 3. run_server.py pattern
```bash
cd ~/projects/ai-memory-system
MNEME_DB_PATH=/tmp/mneme_bench.db .venv/bin/python3 run_server.py
```
Where `run_server.py` calls `create_app()` then `uvicorn.run(app, ...)` — but this may also exhibit the hang depending on shell environment.

## What Didn't Work
- `--workers 1` / `--loop asyncio` flags
- Passing app object vs string to uvicorn.run()
- Using `uvloop` (not available on this RPi Python install)
- Different aiohttp/httpx versions
- `--noproxy '*'` to bypass potential proxy interference
