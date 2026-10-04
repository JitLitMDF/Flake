# Flake — A Private ScriptHub for all your niche games

Recovered + rebuilt clean from the WRD-obfuscated `Loader.lua` / `Keysystem.lua`
(key, UI, colors, layout and flow extracted via live GC/instance dump, then
rewritten as readable source). Made by JitLit_MDF.

## The key

```
PRIVATEJULY26
```

Hardcoded, plaintext compare against the key textbox. No web validation.

## Entry loadstring (paste this in your executor)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/JitLitMDF/Flake/main/Main.lua"))()
```

Or load the pieces individually (both self-bootstrap `Shared.lua`):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/JitLitMDF/Flake/main/Loader.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/JitLitMDF/Flake/main/Keysystem.lua"))()
```

## Files

| File | Role |
|------|------|
| `Main.lua` | Entry point. Loads Shared → Loader → Keysystem, boots `Hub.lua` on auth. |
| `Shared.lua` | Shared runtime state (`getgenv().Flake`), signals, GUI helpers. |
| `Loader.lua` | Intro card: slide-in "Flake" panel, spinner, INITIALIZING → VERIFYING, fires `OnLoaded`. |
| `Keysystem.lua` | Key gate. Waits for loader, validates key, fires `OnAuthorized(key)`. |
| `Hub.lua` | *(not built yet)* the actual script hub, booted after auth. |

## Flow / signals

```
Main.lua
  └─ Loader.lua   → Flake.Loaded = true    → Flake.OnLoaded:Fire()
      └─ Keysystem.lua  waits OnLoaded
          └─ valid key  → Flake.Authorized = true → Flake.OnAuthorized:Fire(key)
              └─ Main.lua boots Hub.lua
```

Shared state lives in `getgenv().Flake`:
`Loaded`, `Authorized`, `Key`, `OnLoaded`, `OnAuthorized`, `Helpers`.
Legacy flat globals `FlakeLoaded` / `FlakeAuthorized` are kept for compatibility.

## Assets / style

- Font: **Michroma** (`rbxasset://fonts/families/Michroma.json`)
- Panel: `RGB(47,47,47)` + white→`RGB(21,21,21)` gradient, 12px corners, 5px white stroke
- Drop shadow: `rbxassetid://6015897843`
- Loader spinner: `rbxassetid://110507486450516`

## Notes on the recovery

- Original was obfuscated with the WeAreDevs free VM obfuscator (not reversible to
  clean source statically). Recovered dynamically by running it in an instrumented
  environment and dumping the decoded constant pool + live instance tree.
- Dropped the original "Tamper Detected!" anti-tamper check — it fights the
  executor's own hooks and breaks loading under most executors. Real protection
  should come from re-obfuscating the finished build.

## TODO

- [ ] Build `Hub.lua` (the post-auth feature menu).
- [ ] Set `KEY_LINK` in `Keysystem.lua` (the "How do I get a key?" destination).
- [ ] Move the key off plaintext / add optional remote key validation if going public.
- [ ] Re-obfuscate the final build with a stronger obfuscator (Luraph / MoonSec tier).
