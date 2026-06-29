# Evennia Attribute vs Model-Field Access (Common Pitfalls)

Evennia `DefaultObject` children (Room, Exit, Character, Item, etc.) have **two parallel data systems** — the **Attribute system** (`db.*`) and the **model fields** (direct properties like `.key`, `.aliases`). Using the wrong one silently does the wrong thing, often causing data-loss-level bugs that only surface on server restart.

## The Core Rule

| Pattern | What it does | Persistence | Searchable? |
|---------|-------------|-------------|-------------|
| `obj.db.key = "xxx"` | Stores an **Attribute** named `"key"` in the Attributes table | ✅ Survives restart | ❌ NOT searchable via `db_key` filter |
| `obj.key = "xxx"` | Sets the **model field** `db_key` on the DB row | ✅ Survives restart | ✅ Searchable via `ObjectDB.objects.filter(db_key=...)` |

## Concrete Bugs Found in Production

### 1. `room.db.key` → room stays findable as old name

```python
# ❌ BUG: sets an Attribute named "key", NOT the room's db_key
room.db.key = "落雁城"

# Next restart:
ensure_room("大片空地")  # STILL finds this room (db_key unchanged!)
# → build_rooms thinks "大片空地" exists, doesn't create new one
# → recovery logic tries to delete "大片空地" and deletes the city room!
```

```python
# ✅ FIX: sets the actual db_key model field
room.key = "落雁城"

# Next restart:
ensure_room("大片空地")  # doesn't find it → creates fresh clone
# → recovery deletes the clone, keeps city room intact
```

### 2. `obj.db.aliases` → aliases silently lost

Evennia aliases are stored in a related model (`ObjectAlias`), managed via `self.aliases.add(...)` / `self.aliases.all()`.

```python
# ❌ BUG: stores an Attribute named "aliases", does nothing useful
obj.db.aliases = ["foo", "bar"]

# ✅ CORRECT: adds to the actual aliases system
obj.aliases.add(["foo", "bar"])
```

### 3. `self.db.destination` → exit points nowhere

`destination` is a `ForeignKey` field on the `ObjectDB` model, not an Attribute.

```python
# ❌ BUG: stores Attribute, doesn't change where the exit leads
exit_obj.db.destination = target_room

# ✅ CORRECT: sets the FK field
exit_obj.destination = target_room
```

### 4. `self.db.location` → character doesn't actually move

Same as `destination` — `location` is a FK field.

```python
# ❌ BUG: character appears to have a location stored but isn't actually there
char.db.location = some_room

# ✅ CORRECT: actually moves the character
char.location = some_room
# OR use the proper mover:
char.move_to(some_room)
```

## How to Tell Which One to Use

**Ask yourself: "Do I need to search/filter objects by this value in the database?"**

| Need | Use | Example |
|------|-----|---------|
| Search/filter in DB queries | **Model field** (direct property) | `room.key`, `exit_obj.destination`, `char.location` |
| Store runtime game data | **Attribute** (`db.*`) | `room.db.donation_progress`, `char.db.hp` |
| Store persistent markers | **Attribute** (`db.*`) | `room.db.donation_city` |
| Aliases | **`obj.aliases` manager** | `obj.aliases.add([...])` |
| Lock/destination/location | **Model field** (direct property) | `exit_obj.destination`, `char.location` |

**Common model-field properties on DefaultObject:**
- `key` → `db_key` (room name, item name, exit direction)
- `aliases` → `AliasManager` (not an Attribute or list)
- `destination` → `db_destination` FK (exits only)
- `location` → `db_location` FK (where the object is)
- `home` → `db_home` FK (fallback location)
- `locks` → `db_lock_storage` (lock string)

**Everything else** (game state, custom data) → use `db.*`.

## Diagnostic Tip

If code "works initially" but breaks on server restart, suspect Attribute-vs-field confusion — Attributes survive restart, but things like `db_key` lookups (`ensure_room`, `ObjectDB.objects.filter(db_key=...)`) don't find them.
