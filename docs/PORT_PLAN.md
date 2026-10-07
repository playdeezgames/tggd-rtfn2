# Port plan: VB.NET to Odin / `js_wasm32`

Status: phases 0 to 3 and 4 (saving) are done and tested (`odin/test.sh`, 48 tests; the browser build was played through by hand). Phase 5 (ship, delete `src/`) waits for the user. The original lives in `src/` (VB.NET, Spectre.Console and Blazor front ends) and is deleted only after the port ships.
Model: the Shark Attackers of SPLORR!! port (`/home/yermom/git/shark-attackers-of-splorr`, `docs/PORT_PLAN.md`). Same toolchain and file split.

## Decisions (the user's, 2026-10-07)

| Question | Answer |
| --- | --- |
| Presentation | **Plain DOM**: real buttons, inputs and links. The 15x15 room is colored text cells in the CGA palette with the Web437 CGA font and tooltips, beside the message log, as the Blazor page did. No canvas. |
| Fidelity | **Exact port.** Quirks go in `docs/QUIRKS.md` and are decided after shipping, not fixed silently. |
| Saves | The original never saved (`World.Save` is never called). The port **saves everything** to `localStorage` and **resumes straight into play**. |
| Layout | New `odin/` beside `src/`; browser only (itch.io `html` channel). `src/` is deleted in its own commit once the port is live. Windows, Linux and Mac downloads are retired. |

## 1. What the game is (verified from the VB code)

A turn-based maze crawler. The world is a **5 by 4 maze of rooms**, each room 15 by 15 tiles. The player is a "N00b" with biology: eat food, poop, avoid starving, keep their sanity. Tax forms are filled out and signed. There is **no win condition and no combat**.

### World generation (`Embark`)

1. Name prompt (`What is your name?`, text). The unused `DEFAULT_NAME` is ignored.
2. Maze: randomized Prim. Pick a random start cell; the frontier is its neighbors. Repeatedly take a random frontier cell, open the door to a random neighbor already inside, add the cell, add its outside neighbors that are not already in the frontier.
3. Each room: border tiles are walls (`#`, blocked), everything else floor (`.`). For each open door the tile at N (7,0), E (14,7), S (7,14), W (0,7) becomes floor and gets a **door feature** whose destination is the neighbor room's tile on the opposite edge: N goes to (7,14), E to (0,7), S to (7,0), W to (14,7). A door is **locked** when the room it leads into has exactly one door (a dead end).
4. Keys: one per dead-end room, each on a random free floor tile (no feature, no character) of a random room with more than one door.
5. Items and features, each placed by picking a random room, then a random tile in it, retrying until the spawner accepts:

   | Count | Thing | Accepted when |
   | --- | --- | --- |
   | 100 | food item (`4d6` stomach, verb Eat) | room has 2+ doors, tile is floor, no feature, no character |
   | 25 | Tax Form feature | tile is floor |
   | 5 | Pen # 15 item (ink 20/20) | tile is floor |
   | 5 | Ink Well feature | tile is floor (the code's condition is muddled but works out to this; see quirks) |

6. Avatar: random room with 4 doors, else 3, else 2; random free floor tile.
7. Message `Welcome to Feretory of SPLORR!!`, then Look.

### Stats (avatar)

| Stat | Start | Min | Max |
| --- | --- | --- | --- |
| Satiety | 100 | 0 | 100 |
| Health | 100 | 0 | 100 |
| Stomach | 0 | 0 | 50 |
| Bowel | 0 | 0 | 50 |
| Sanity | 100 | 0 | 100 |

Dead = health at minimum. Insane = sanity at minimum. Both only block Move and Poop (`CanAct`); everything else still works, including entering doors.

### Counter changes

`DoChangeCounter(entity, counter, delta)`: when delta is not 0 it prints `<name> gains|loses <|delta|> <counter>.`, applies the change clamped to the counter's range, then prints `<name> now has <value>/<max> <counter>.` The message uses the requested delta even when clamping cuts it short. Counter names: stomach, health, satiety, bowel, ink, sanity, completeness.

### Move (avatar verbs N, E, S, W; each needs `CanAct`)

- Target outside the room or a wall: `<name> cannot move <north|east|south|west>.`
- Otherwise: if sanity is not max, a 50% roll adds 1 sanity (with its messages); then `<name> moves <dir>.`; then **biology** (1 step); then the avatar moves; then Look.

### Biology (`DoBiology(1)`, avatar only, not when dead)

```
stomach = min(amount, stomach)
if stomach > 0:
    amount -= stomach; stomach -= stomach (message)
    bowel_gain = min(stomach_amount, bowel capacity); damage += stomach_amount - bowel_gain
    if damage > 0: "<name> takes damage from having a full bowel!"
    bowel += bowel_gain (message)
satiety_use = min(amount, satiety)
if satiety_use > 0: amount -= satiety_use; satiety -= satiety_use (message)
else if satiety is max: if health is not max and damage <= 0: health += 1 (message)
else: satiety += 1 (message)
damage += amount
if damage > 0: health -= damage (message)
```

### Other verbs

- **Look**: dead: `<name> is dead.`; insane: `<name> is insane.`; else `<name> is on floor.`, `There is stuff on the ground.` if the tile has items, then `Features:` and `- <name>` per feature on the tile.
- **Status**: `Status:`, then `Stomach: a/b`, `Bowel`, `Satiety`, `Health`, `Sanity`.
- **Poop!** (needs `CanAct` and bowel at least 25): finds or creates the `poo pile` feature on the tile, moves `bowel \ 2` from bowel (with messages) into the pile's poo. No Look.
- Every verb clears the message log first.

### Features and their verbs

| Feature | Name | Describe | Verbs (menu order) |
| --- | --- | --- | --- |
| Door | `door` | `This is a door.` plus `door is locked.` if locked | **Enter** (not locked): `<name> enters door.`, move to destination, Look. **Unlock** (locked and a key in inventory): `<name> unlocks door.`, clear lock, consume a key. |
| Tax Form | `Tax Form` | `This is a Tax Form.`, `Compleness: N%` (sic) | **Fill Out** (not complete, a pen with ink): first pen with ink loses 1 ink, form gains 1 completeness, avatar loses 1 sanity. **Sign** (complete, a pen with ink): `<name> signs Tax Form.`, pen loses 1 ink, avatar gains 10 sanity, form removed. |
| Ink Well | `Ink Well` | `This is a Ink Well.` | **Refill Pen** (a pen below full): first such pen gains its missing ink. |
| Poo pile | `poo pile` | `This is a poo pile.`, `poo pile has N poo.` | none |

### Items

| Item | Name | Describe | Verbs |
| --- | --- | --- | --- |
| Food | `food` | `It is a food.` | Eat: avatar gains the food's stomach value, food consumed |
| Key | `key` | `It is a key.` | none |
| Pen | `Pen #15` | `It is a Pen #15.`, `Ink: a/b` | none |

Items are grouped into stacks by kind; a stack is named `<name>(x<count>)`.

### Menus (the choices a screen shows are only the enabled ones)

- **Title**: elements `Feretory of SPLORR!!` (h1), `A Production of ` + link TheGrumpyGameDev (https://thegrumpygamedev.itch.io/), `For: ` + link `roguetemple's Fortnight 2` (https://itch.io/jam/roguetemples-fortnight-2), `Sponsored by: `, links `UMLAUT.FYI!` (https://umlaut.fyi/), `Pen 15!` (https://pen15.site/), `Jargonize!` (https://jargonize.app/). One choice: `OK`.
- **Main Menu:** `Embark!` (Quit is hidden in the browser build).
- **Now What?** (navigation): N, E, S, W, Look, Status, Poop!, `Ground...` (tile has items), `Inventory...` (avatar has items), `<feature name>...` for each feature on the tile, `Watch Ad...`, `Gämë Mënü`. Messages and the room grid show above every in-play menu.
- **Feature menu** (`Do what with <name>?`): describes the feature first (clears the log), then `Never Mind`, `Items...` (always hidden: features never hold items), then its enabled verbs. A verb runs and returns to Now What?.
- **Inventory:** `Inventory:` with `Never Mind` and the stacks. A stack of 1 goes straight to its item; a larger one shows `Items in stack:` with `Never Mind`, `Drop One` (count above 1), `Drop Half(n)` (count above 3), `Drop All` (count above 1), then `<name>...` per item. An item shows `Do what with <name>?` (after describing it, which clears the log) with `Never Mind`, `Drop`, then its verbs. Eat runs and shows an `Ok` screen. Drop prints `<name> drops <item>.` or `drops <n> <name>.` and returns to the inventory, or to Now What? when it is empty.
- **Ground:** the same shape with `On the ground:`, `Take One`, `Take Half(n)`, `Take All`, `Take`. Items are not described when selected.
- **Ads:** `Watch Ad...` starts a 2-minute real-time break. While it runs, in-play shows only the ad screen: `Time left in ad break: mm:ss`, the turn-based note, one random sponsor link (Umlaut.fyi, Pen 15, Jargonize, equal weight) and an `Ok` button that refreshes. When time is up it says `Ad break is complete! You may return to yer metaphor!` and clears the break.
- **Game menu:** `Continue`, `Abandon` (confirm `Are you sure you want to abandon?`, `No`/`Yes`). Abandon wipes the world and returns to the Main Menu.
- The `Gämë Mënü` spelling is an intentional umlaut gag for a sponsor. Keep it.

### Grid

One cell per tile of the avatar's room, drawn after every in-play menu. Per tile the first of: character, first feature, first ground item, then the tile itself. Glyph and CGA attribute (`fg = attr & 15`, `bg = attr >> 4`):

| Thing | Glyph | Attribute |
| --- | --- | --- |
| Avatar | `@` | 0x0F |
| Door | `+` | 6 |
| Poo pile | `~` | 6 |
| Ink Well | `I` | 9 |
| Tax Form | `T` | 0xF0 |
| Food | `f` | 12 |
| Pen | `/` | 1 |
| Key | `k` | 14 |
| Wall | `#` | 0x91 |
| Floor | `.` | 7 |

The tooltip is that thing's name (the avatar's chosen name, `door`, `food`, `wall`, `floor`, ...). Title, Main Menu, Game Menu and the confirm dialog do not refresh the grid, so they keep showing the last one.

## 2. Architecture (`odin/`)

```
odin/
  game.odin          pure rules and world generation, no browser imports
  screens.odin       menu state machine, builds a View (elements, grid, prompt)
  save.odin          JSON save and load, strict validation
  web.odin           #+build js: dom_* imports, storage, exports
  web/index.html     DOM renderer, CGA colors
  web/fonts/         Web437_IBM_CGA.woff (copied from src/Metaphor.Blazor/wwwroot/fonts)
  *_test.odin        #+build !js
  build.sh, test.sh
shippit.sh           rewritten: test, build, zip, butler push only with --push
```

- The entity/yoke/yokage framework collapses into plain structs: rooms (door bit sets), a flat feature array and a flat item array in creation order, and one avatar. Capacity limits: 5000 features (4500 tiles can each hold a poo pile, plus about 70), 512 items.
- The clock and random numbers are inputs where tests need to control them (`Env` as in Shark Attackers); world generation uses the default random generator, which tests seed with `rand.reset`.
- Numbers: `4d6` for food is four rolls of 1 to 6.
- `localStorage` key `feretory:save`, version 1, enums as integers and every field range-checked on load; Abandon writes an `empty` marker.

## 3. Phases

0. Scaffold: `odin/` folder, `build.sh`, `test.sh`, `.gitignore` entries, a trivial program that builds to wasm.
1. Pure rules and tests: maze, world generation invariants (every room reachable, locked doors exactly at dead ends, key count, item counts), movement, biology, verbs, inventory and ground operations.
2. Screens as a state machine plus tests that play through the same `choose` calls a click would.
3. DOM web shell and visual check in the browser.
4. Save and load.
5. Ship (only on the user's say-so): rewrite `shippit.sh`, `--push`, then delete `src/` in its own commit and update README and CLAUDE.md.

## 4. Open items

- Whether the stale grid on the Main Menu after Abandon should stay.
- Whether starvation (see quirks) should keep alternating health loss.
