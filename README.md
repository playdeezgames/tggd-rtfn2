# Feretory of SPLORR!!

A Production of TheGrumpyGameDev

![Feretory of SPLORR!!](ss/cover.png)

A turn-based maze crawl through a 5 by 4 grid of rooms. Eat, poop, keep your sanity, fill out tax forms, and find the keys to the dead ends. There is no way to win.

- Play it: https://thegrumpygamedev.itch.io/feretory-of-splorr
- Made for: [roguetemple's Fortnight 2](https://itch.io/jam/roguetemples-fortnight-2)

![Screenshot](ss/ss1.png)

## Building

The game is Odin compiled to WebAssembly (`odin/`). It was ported from VB.NET; see `docs/PORT_PLAN.md` for the rules and `docs/QUIRKS.md` for the changes made along the way.

```bash
odin/test.sh                                # tests
odin/build.sh                               # builds odin/out
python3 -m http.server 8123 -d odin/out     # then open http://localhost:8123/
```

The original VB.NET version is in git history up to commit `5774c50`.

## Notes

Design notes live in the author's Obsidian vault at `/home/yermom/git/bok-of-splorr/splorr/`.
