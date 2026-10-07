# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

*Feretory of SPLORR!!* — a game by TheGrumpyGameDev, made for the RogueTemples Fortnight 2 jam. Published at https://thegrumpygamedev.itch.io/feretory-of-splorr (jam: https://itch.io/jam/roguetemples-fortnight-2).

The author calls their games "interactive experiences (Metaphors)": the mechanic and presentation are the message. Keep the "of SPLORR!!" branding, keep text short and deadpan, and don't "fix" difficulty that exists to make the metaphor land. The author's Obsidian vault (`/home/yermom/git/bok-of-splorr/splorr/`, outside this repo) holds design notes, e.g. `Concepts/Metaphor design.md`, `Tech/Shipping to itch.io.md` and `Gotchas.md`.

## Overview

The game is Odin compiled to `js_wasm32`, shipped to itch.io as a browser game. It was ported from VB.NET (Spectre.Console and Blazor front ends), which lives in git history up to commit `5774c50`. Read `docs/PORT_PLAN.md` (verified rules of the original, decisions) and `docs/QUIRKS.md` (what was kept or changed from the original, and why) before changing game behavior.

```bash
odin/test.sh            # native tests (one thread; the soak test takes ~15 s)
odin/build.sh           # builds odin/out (game.wasm, odin.js, index.html, fonts)
python3 -m http.server 8123 -d odin/out   # then open http://localhost:8123/ (not file://)
```

- `odin/game.odin` rules and world generation (no browser imports), `screens.odin` menu state machine producing a `View`, `save.odin` JSON save (`feretory:save` in localStorage) with strict validation, `web.odin` (`#+build js`) the only file with browser imports, `web/index.html` the DOM renderer.
- Odin is at `/home/yermom/ODIN/odin` (override with `$ODIN`). Test files are `#+build !js`.
- Keep `Gämë Mënü` with its umlauts (a sponsor gag).
- `./shippit.sh` tests, builds and zips; `--push` uploads to itch.io (`thegrumpygamedev/feretory-of-splorr:html`, public). Do not run it with `--push`, or `git push`, unless the user says so. Commit first so live matches the repo.
