---
name: chinese-messaging-platforms
description: "Configure and manage Chinese messaging platforms on Hermes Gateway — QQ Bot, WeChat (Weixin), DingTalk, Feishu/Lark, WeCom, and Yuanbao."
version: 1.0.0
author: Hermes Agent
tags: [hermes, gateway, qq, wechat, weixin, dingtalk, feishu, lark, wecom, yuanbao, messaging, chinese-platforms]
---

# Chinese Messaging Platforms

Configure Hermes Gateway to connect with Chinese messaging platforms. Each platform has its own setup, but they share a common pattern:

1. Obtain credentials from the platform's developer console
2. Set environment variables in `~/.hermes/.env`
3. Enable the platform in `~/.hermes/config.yaml` under `platforms:`
4. Verify the platform_toolsets mapping exists
5. Start or restart the gateway

## Supported Platforms

| Platform | Toolset | Env Vars Needed | Docs Link |
|----------|---------|-----------------|-----------|
| QQ Bot | `hermes-qqbot` | `QQ_APP_ID`, `QQ_CLIENT_SECRET` | [QQ Bot Setup](../docs/user-guide/messaging/qqbot) |
| Weixin (WeChat) | `hermes-weixin` | `WEIXIN_APP_ID`, `WEIXIN_APP_SECRET`, `WEIXIN_TOKEN`, `WEIXIN_AES_KEY` | [Weixin Setup](../docs/user-guide/messaging/weixin) |
| DingTalk | `hermes-dingtalk` | `DINGTALK_CLIENT_ID`, `DINGTALK_CLIENT_SECRET` | [DingTalk Setup](../docs/user-guide/messaging/dingtalk) |
| Feishu / Lark | `hermes-feishu` | `FEISHU_APP_ID`, `FEISHU_APP_SECRET` | [Feishu Setup](../docs/user-guide/messaging/feishu) |
| WeCom | `hermes-wecom` | `WECOM_CORP_ID`, `WECOM_AGENT_ID`, `WECOM_SECRET` | [WeCom Setup](../docs/user-guide/messaging/wecom) |
| WeCom Callback | `hermes-wecom-callback` | `WECOM_CORP_ID`, `WECOM_CALLBACK_TOKEN`, `WECOM_CALLBACK_AES_KEY` | [WeCom Callback Setup](../docs/user-guide/messaging/wecom-callback) |
| Yuanbao | `hermes-yuanbao` | `YUANBAO_APP_ID`, `YUANBAO_APP_KEY` | [Yuanbao Setup](../docs/user-guide/messaging/yuanbao) |

## Quick Reference: Common Steps

```bash
# 1. Set credentials
# Edit ~/.hermes/.env with the platform's required env vars

# 2. Enable platform in config
hermes config set platforms.<platform>.enabled true

# 3. Verify platform_toolsets mapping
# Already mapped in default config for most platforms

# 4. Start the gateway
hermes gateway run          # foreground (test)
hermes gateway install      # background service
hermes gateway start        # start service

# 5. Check logs
tail -f ~/.hermes/logs/gateway.log
```

## Explicitly Unsupported Platforms

These platforms are known to NOT have accessible APIs or Hermes integration:

| Platform | Reason |
|----------|--------|
| **小红书 (Xiaohongshu / RedNote)** | No public content-posting API. Only MCN/brand-facing commercial APIs for ads and analytics. Posting via automation (browser, RPA) is fragile and against ToS. **Reading** public notes is possible via `web_extract` on note URLs. |

## Common Pitfalls

- **Platform not in `platform_toolsets`**: Check `~/.hermes/config.yaml` for a `platform_toolsets:<platform>: - hermes-<platform>` entry. If missing, add it manually.
- **Gateway ignores changes**: Config changes for platforms require gateway restart (`hermes gateway restart`), not just a new CLI session.
- **Intents not enabled**: Most platforms require enabling specific message intents (C2C, group, guild) in the developer console before they'll deliver messages.
- **Sandbox mode**: QQ Bot and some other platforms have a sandbox/test mode that only delivers messages from test accounts. Check the platform's dev portal.
- **Secret redaction**: Displaying platform secrets in terminal output may be redacted by Hermes. Use `xxd` or `hexdump` to verify file contents when needed.
- **Duplicate env vars**: Accidentally appending a duplicate `*_SECRET` or `*_KEY` line to `.env` is harmless (last one wins) but messy. Clean up with `sed` or Python.

## Reference Files

- `references/qqbot-setup.md` — Full walkthrough for QQ Bot configuration
