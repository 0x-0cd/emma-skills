# Widget Testing Reference

Shell commands to verify each widget before adding to README.

## GitHub Stats

```bash
# Dark theme
curl -s "https://github-readme-stats.vercel.app/api?username=0x-0cd&show_icons=true&hide_border=true&ring_color=008c8c&title_color=008c8c&icon_color=008c8c&text_color=ffffff&bg_color=0d1117" | head -3

# Light theme
curl -s "https://github-readme-stats.vercel.app/api?username=0x-0cd&show_icons=true&hide_border=true&ring_color=008c8c&title_color=008c8c&icon_color=008c8c&bg_color=ffffff" | head -3
```

Expected: returns SVG starting with `<svg`

## Top Languages

```bash
curl -s "https://github-readme-stats.vercel.app/api/top-langs/?username=0x-0cd&layout=compact&hide_border=true&title_color=008c8c&text_color=ffffff&bg_color=0d1117" | head -3
```

## Contribution Streak

```bash
curl -s "https://github-readme-streak-stats.herokuapp.com?user=0x-0cd&theme=transparent&hide_border=true&ring=008c8c&fire=e85827" | head -3
```

Expected: returns SVG. Note: herokuapp has cold start delay (~3s first load).

## Trophy (unreliable — test first)

```bash
curl -s "https://github-profile-trophy.vercel.app/?username=0x-0cd&theme=darkhub" | head -3
```

May return 503 (Vercel free tier). If so, skip.

## Activity Graph

```bash
curl -s "https://github-readme-activity-graph.vercel.app/graph?username=0x-0cd&custom_title=Commit%20Statistics&hide_border=true&bg_color=0d1117&title_color=008c8c&color=ffffff&line=008c8c&point=e85827&radius=16" | head -3
```

## Visitor Badge

```bash
# Primary (komarev)
curl -s "https://komarev.com/ghpvc/?username=0x-0cd&color=008c8c&style=for-the-badge"

# Fallback (if komarev 403s)
curl -s "https://visitor-badge.laobi.icu/badge?page_id=0x-0cd.0x-0cd"
```

## Pin Cards (Featured Repos)

```bash
curl -s "https://github-readme-stats.vercel.app/api/pin/?username=0x-0cd&repo=emma-skills&hide_border=true&bg_color=0d1117&title_color=008c8c&text_color=ffffff&icon_color=008c8c" | head -3
```

Replace `repo=` with each featured repo name.

## Dark/Light Mode URL Pattern

```html
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="URL_WITH_DARK_PARAMS">
  <source media="(prefers-color-scheme: light)" srcset="URL_WITH_LIGHT_PARAMS">
  <img src="URL_WITH_DARK_PARAMS" alt="...">
</picture>
```

Key parameter differences between dark and light:
- `bg_color`: `0d1117` (dark) vs `ffffff` (light)
- `text_color`: `ffffff` (dark) vs omit (light uses default black)
- `currStreakLabel`: `ffffff` (dark) vs `000000` (light)
- `dates`: `666666` (dark) vs `999999` (light)
- `sideLabels`: `888888` (dark) vs `666666` (light)
