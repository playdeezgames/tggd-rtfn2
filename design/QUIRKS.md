# Questionable quirks of the original

Found while porting. The Odin port reproduces them (exact port); decide after it ships.

- **Starvation alternates.** *(Fixed in the port, 2026-10-07: starving now costs 1 health every step and satiety stays at 0.)* In the original, with no stomach contents and satiety at 0, `DoBiology` added 1 satiety and still applied 1 damage, so health dropped every other move.
- **Dead and insane avatars can still act.** *(Fixed in the port, 2026-10-07: at 0 health or 0 sanity the menu is only Look, Status, Watch Ad... and Gämë Mënü; no doors, items or forms.)* In the original only Move and Poop were blocked, and `YerDeadMenu` and `DonePrompt` existed but were never shown.
- **Several features on one tile.** *(Fixed in the port, 2026-10-07: Tax Forms and Ink Wells only spawn on floor tiles with no feature, so a fresh world has at most one feature per tile. Pens can still share a tile with a feature. Poo piles can still land on a feature.)* In the original they ignored what was already there, so a door could carry a Tax Form; the grid showed only the first feature while Look and the menu listed all.
- **Item stacks drop a message.** *(Fixed in the port, 2026-10-07: the leftover item is described below the `drops` message instead of replacing it.)* In the original, Drop One on a stack of 2 left 1 item whose screen described it, which cleared the message.
- **Inventory order is a hash set.** The original lists items in `HashSet` order, which is creation order until something is removed. The port uses creation order. *(Decided 2026-10-07: keep creation order.)*
- **The grid is stale.** *(Fixed in the port, 2026-10-07: the picture is cleared when the game is abandoned. The Game Menu and the confirm still show the current room.)* In the original those screens did not refresh it, so the Main Menu kept showing the last room after Abandon.
- `ChooseNamePrompt.DEFAULT_NAME` (`Olen Kyrpa`) is never used. The name prompt accepts an empty string (nameless avatar). *(Changed in the port, 2026-10-07: the name box starts with `Olen Kyrpa`, selected so typing replaces it, and a non-empty name is required.)*
- `Compleness` is misspelled in the Tax Form description. *(Fixed in the port, 2026-10-07: `Completeness`.)*
- `This is a Ink Well.` uses the wrong article. *(Fixed in the port, 2026-10-07: `This is an Ink Well.`)*
- Quit is disabled in the browser build, so the Main Menu has one entry. *(Decided 2026-10-07: keep.)*
- Feature inventories (`Items...` on a feature) exist in code but are always empty and always hidden. *(Moot, 2026-10-07: unreachable.)*
- `Map.Remove` is a TODO; `Metaphor.Platform` and the Spectre front end never cleaned up, and `World.Save` is never called, so the original never saved. The port saves on purpose.
- `GetCounterStatistic` shows `value/max`, but `DoChangeCounter` shows just the value when the maximum is `Integer.MaxValue` (the poo counter, which is never reported that way). *(Moot, 2026-10-07: unreachable.)*
- The ad countdown only refreshes when Ok is clicked (turn based by design). *(Decided 2026-10-07: keep.)*
- `Gämë Mënü` is an intentional umlaut gag for a sponsor. Keep it.
