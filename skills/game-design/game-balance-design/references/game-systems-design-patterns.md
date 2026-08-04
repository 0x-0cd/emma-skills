# Layered Legacy System & GUI+Command Dual-Track Architecture

> Captured from XunDaoMUD redesign session (2026-08). Reusable patterns for roguelite/persistent-online hybrid game design.

---

## Pattern 1: Layered Legacy System (死亡删档 + 局外养成)

### Core Concept
Character death triggers partial resource inheritance through tiered layers, balancing tension (death matters) with retention (not all is lost).

### Three-Layer Design

| Layer | Mechanism | Lore Justification | Player Driver |
|-------|-----------|-------------------|---------------|
| **天道传承** (Heavenly Legacy) | Auto-inherit on death: 30% currency + skill fragments + all materials. Equipment and complete skills NOT retained. | "天道轮回，前世道基化为道种，随魂魄转世" | Growth |
| **宗门传承** (Sect Legacy) | Deposit rare items in sect vault; other members "guard" them. Retrieve on reincarnation. | "同门之谊，师兄代守前辈遗泽" | Social |
| **世间遗落** (World Drops) | High-value items scatter on death, becoming exploration points discoverable by other players. | "大能陨落，宝物散落，有缘者得之" | Exploration/Competition |

### Design Principles
- **Heavenly Legacy is the safety net** — solo/new players can always progress
- **Sect Legacy is the bonus** — social play is rewarded, not required
- **World Drops are the driver** — your death becomes someone else's adventure
- All four drivers (social/exploration/growth/competition) represented in one system

### Numerical Anchors
- Currency: 30% retained (tune 20-40%)
- Materials: 100% retained (low impact, high feels-good)
- Equipment: 0% retained (provides next-life motivation)
- Complete skills: 0% retained (fragments only — 50% chance per skill)
- Upper bound: cap total inherited value at ~40% of character's peak net worth

### Pitfalls
- **Over-inheritance → no tension**: If too much is retained, death becomes a minor inconvenience
- **Under-inheritance → retention death**: New players with no legacy have worst experience; consider a "first life bonus"
- **Sect dependency = fragility**: If the game's player base is small, Sect Legacy becomes unreliable. Design Heavenly Legacy to be sufficient on its own.
- **Progression ceiling**: If a player inherits too well over many lives, difficulty may collapse. Consider diminishing returns on inherited resources across lives.

---

## Pattern 2: GUI + Command Dual-Track Architecture

### Core Concept
Frontend presents GUI (buttons, clickable text, tap targets) but internally translates all interactions to command strings sent over WebSocket. Command system is the canonical protocol; GUI is a rendering layer.

```
Player taps [攻击] button
  → Frontend sends "attack 怪物名" via WebSocket
  → Server's CommandHandler parses and executes
  → Result sent back to frontend for rendering
```

### Benefits
- **Frontend-swappable**: Change UI without touching server logic
- **Plugin extensibility**: Players with dev skills can write CLI tools/bots/browsers using the command protocol directly
- **Debug/test bypass**: Connect via raw WebSocket/telnet, skip GUI entirely
- **Cross-platform**: Same command protocol works on web, mobile app, or desktop client

### Implementation Pattern (inspired by wsmud)

```python
# Frontend (Vue component)
function onAttackTap(targetName) {
  ws.send(JSON.stringify({ type: 'command', text: `attack ${targetName}` }))
}

# Server (Python command handler)
class CommandHandler:
    def handle(self, cmd_string: str, player):
        parts = cmd_string.split(maxsplit=1)
        cmd_name, args = parts[0], parts[1] if len(parts) > 1 else ""
        
        cmd_map = {
            "attack": CmdAttack,
            "look": CmdLook,
            "say": CmdSay,
            # ... full command registry
        }
        
        cmd_class = cmd_map.get(cmd_name)
        if cmd_class:
            cmd_class().parse(args).execute(player)
        else:
            player.msg("未知命令")
```

### Design Constraints
- Command strings must be UTF-8, max 512 bytes
- Frontend should provide autocomplete/suggestions based on available commands in current context
- Commands are context-sensitive (combat commands only available in combat state)
- Error messages must be player-friendly (not stack traces)

### Reference
- wsmud uses this pattern: GUI buttons send MUD commands internally
- Evennia's CmdSet system is architecturally similar but heavier; this pattern strips it to essentials

---

## Cross-Reference
- See `references/game-content-documentation.md` for content table standards
- See `references/game-balance-design.md` for numerical balance methodology
- See `references/damage-variance-implementation.md` for combat feel design
