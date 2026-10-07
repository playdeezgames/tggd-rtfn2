# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

*Feretory of SPLORR!!* — a game by TheGrumpyGameDev, made for the RogueTemples Fortnight 2 jam. Published at https://thegrumpygamedev.itch.io/feretory-of-splorr (jam: https://itch.io/jam/roguetemples-fortnight-2).

The author calls their games "interactive experiences (Metaphors)": the mechanic and presentation are the message. Keep the "of SPLORR!!" branding, keep text short and deadpan, and don't "fix" difficulty that exists to make the metaphor land. The author's Obsidian vault (`/home/yermom/git/bok-of-splorr/splorr/`, outside this repo) holds design notes, e.g. `Concepts/Metaphor design.md`, `Tech/Shipping to itch.io.md` and `Gotchas.md`.

## Commands

Everything lives under `src/` (.NET 10, solution `src/Metaphor.slnx`). There are no tests or linters in the repo.

```bash
dotnet build src/Metaphor.slnx
dotnet run --project src/Metaphor.Spectre/Metaphor.Spectre.vbproj   # terminal build
dotnet run --project src/Metaphor.Blazor/Metaphor.Blazor.csproj     # browser build (WASM dev server)
```

Projects set `TreatWarningsAsErrors` and `OptionStrict On`, so warnings break the build.

### Shipping

`shippit.sh` publishes self-contained single-file builds for linux/windows/mac (Spectre) plus the Blazor WASM build, deletes `.pdb` files, then runs `butler push` to the itch.io channels `windows`, `linux`, `mac` and `html`.

- It is not executable: run it as `bash shippit.sh` from the repo root.
- It publishes publicly. Only run it when the user explicitly asks, and commit first so live matches the repo.

## Architecture

Mostly VB.NET (Blazor project is C#/Razor). Projects come in `Metaphor.*` (game-specific) and `TGGD.*` (reusable framework) pairs, grouped in the solution by layer number:

1. **Provision**: serializable data classes (`WorldData`, `EntityData`, `MessageData`) used for save/load.
2. **Persistence**: entity/world state wrappers (`IEntity`, `IWorld`, `ICharacter`, ...) over the provision data, plus the `IPersister` interface (`SaveAsync`/`LoadAsync` of a filename and a string).
3. **Extensions**: extension methods over persistence types holding the game logic (characters, features, items, locations, maps, verbs, `TGGD.Extensions.Maze` generation, `RNG`).
4. **Models**: `IModel`/`WorldModel`, which wrap the world and its persister. Note the root namespace here is `*.Processing`, not `*.Models`.
5. **Presentation**: dialog/menu/prompt/grid abstractions (`IDialog`, `IDialogPrompt`, `IGrid`, `IDisplayContext`). `Metaphor.Presentation` has the actual screens (Boilerplate menus, `Embark`, `InPlay`).
6. **Platform**: `IDisplay`/`Display` exposes the current `Grid`, `Elements` (narrative text, titles, links, tagged with hints such as `ElementTypes`/`HintNames`) and a `Prompt`. `MetaphorDisplay.Create(quittable, persister)` starts at the Title screen.
7. **Play**: frontends, each a thin renderer over `IDisplay`.
   - `Metaphor.Spectre`: Spectre.Console loop (clear, render grid and elements, read the prompt by `DialogPromptType`). Its `Persister` writes files.
   - `Metaphor.Blazor`: WASM page `Pages/Home.razor` renders the same grid and elements as HTML tables.

Dependencies flow downward only: a frontend references `Metaphor.Platform`, which references `Metaphor.Presentation` and `TGGD.Platform`. Game logic should live in Extensions/Models, never in a frontend. When adding a new frontend feature, extend the `IDisplay` contract so both frontends keep working.
