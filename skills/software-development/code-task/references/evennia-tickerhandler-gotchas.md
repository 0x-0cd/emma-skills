# Evennia TickerHandler + ndb Gotchas

> Targets: XunDaoMUD (Evennia 6.0.0). Applies to any game using Evennia's `TICKER_HANDLER`.

## Architecture

Evennia's `TickerHandler` (global instance `TICKER_HANDLER`) implements subscription-based tickers:

```python
from evennia.scripts.tickerhandler import TICKER_HANDLER

# Add: returns a store_key tuple
store_key = TICKER_HANDLER.add(
    interval=5,                    # seconds (floored to int, min 1)
    callback=obj.at_method,        # method on a typeclassed object
    idstring="unique_id",          # distinguish same interval+callback with different args
    persistent=False,              # False = survives reload but not cold restart
    *args, **kwargs                # passed to callback on each tick
)

# Remove by store_key (preferred) or by interval+callback+idstring
TICKER_HANDLER.remove(store_key=store_key)
```

## The store_key Tuple

`add()` returns a tuple:

```python
(packed_obj, methodname, outpath, interval, idstring, persistent)
```

- `packed_obj` — serialized form of the typeclass object
- `methodname` — string name of the method (e.g. `"at_xiulian_tick"`)
- `outpath` — Python path for standalone functions
- `interval` — int seconds
- `idstring` — unique identifier
- `persistent` — bool

## The ndb store_key Problem

### Pattern used in XunDaoMUD

All idle-task systems (cultivate, liaoshang, caiyao, wakuang) follow the same pattern:

```python
# _start_xxx(caller):
store_key = TICKER_HANDLER.add(..., persistent=False)
caller.ndb._xxx_store_key = store_key    # stored in NON-persistent attribute

# _stop_xxx(caller):
store_key = getattr(caller.ndb, "_xxx_store_key", None)
if store_key:
    TICKER_HANDLER.remove(store_key=store_key)
```

### Root cause of orphaned tickers

| Event | ndb store_key | Ticker |
|-------|---------------|--------|
| Player starts task | Saved ✅ | Registered ✅ |
| Server reload (`evennia reload`) | **LOST** ❌ (ndb cleared) | **Survives** ✅ (persistent=False survives reload) |
| Player uses `stop` after reload | `getattr()` returns `None` → remove short-circuits | Ticker **continues running** ❌ |
| Player moves freely | `idle_task` was set to `None` → no movement block | Ticker fires → wrong room → weird messages |

### Fix options

1. **Don't rely on ndb store_key** — pass `interval+callback+idstring+persistent` to `remove()` instead:

   ```python
   TICKER_HANDLER.remove(
       interval=CULTIVATE_INTERVAL,
       callback=caller.at_xiulian_tick,  # method is stable
       idstring=f"xiulian_{caller.id}",
       persistent=False,
   )
   ```

   This reconstructs the store_key internally, so it works regardless of ndb state.

2. **Alternative: store store_key in db** — but Evennia has a known bug where serializing store_key through db breaks it (see [Evennia #3759](https://github.com/evennia/evennia/issues/3759)). So this is NOT recommended.

3. **Store interval + idstring in ndb** (redundant with the callback, but serves as cross-check).

### All idle_task systems affected

- `cultivate` / `xiulian` — `_xiulian_store_key` + `idstring=f"xiulian_{caller.id}"`
- `liaoshang` — `_liaoshang_store_key`
- `caiyao` — `_caiyao_store_key`
- `wakuang` — `_wakuang_store_key`

Fix should be applied uniformly to all four.

## Sub-second tickers not supported

Tickers with `interval < 1` raise `RuntimeError`. Floats are floored to int.

## Non-persistent ticker lifecycle

| Event | Persistent=True | Persistent=False |
|-------|----------------|-----------------|
| Server reload | Restored ✅ | Restored ✅ |
| Cold restart | Restored ✅ | Discarded ❌ |
| ndb loss | N/A | store_key lost → orphan risk |

## References

- Evennia source: `evennia/scripts/tickerhandler.py`
- Evennia 6.0.0 tag: https://github.com/evennia/evennia/tree/v6.0.0
- Store_key serialization bug: https://github.com/evennia/evennia/issues/3759
