package feretory

// The menu/dialog state machine, ported from Metaphor.Presentation. Pure: it
// reads and drives `Game` and produces a `View` for a front end to draw.
// Choices that are not available are left out of the list (the original's
// DialogPrompt drops disabled choices); they are never shown greyed out.

import "core:fmt"

Screen :: enum {
	Title,
	Main_Menu,
	Choose_Name,
	Game_Menu,
	Confirm_Abandon,
	Ad_Menu,
	Nav_Menu,
	Feature_Menu,
	Item_Verb_Done,
	Inventory_Menu,
	Inventory_Stack_Menu,
	Inventory_Item_Menu,
	Ground_Menu,
	Ground_Stack_Menu,
	Ground_Item_Menu,
}

Action :: enum {
	Title_Ok,
	Embark,
	Continue,
	Abandon,
	Confirm_No,
	Confirm_Yes,
	Never_Mind,
	Avatar_Verb,
	Feature, // open the menu of a feature on this tile
	Feature_Verb,
	Item_Verb,
	Ground,
	Inventory,
	Stack, // open a stack (kind)
	Item, // open one item (index)
	Drop,
	Drop_Stack, // arg is how many; 0 means all
	Take,
	Take_Stack,
	Watch_Ad,
	Game_Menu,
	Ok,
}

Choice :: struct {
	text:   string,
	action: Action,
	arg:    int, // verb, feature/item index, kind or count, depending on the action
}

Prompt_Kind :: enum {
	Choice,
	Text,
}

Prompt :: struct {
	kind:    Prompt_Kind,
	title:   string,
	initial: string, // for .Text: what the box starts with
	choices: []Choice, // for .Choice
}

Element_Kind :: enum {
	Text,
	Title,
	Link,
}

Element :: struct {
	kind:     Element_Kind,
	text:     string,
	href:     string,
	new_line: bool,
}

// One tile of the room picture. The tooltip is copied, so it outlives the game.
Cell :: struct {
	ch:      u8,
	attr:    u8, // CGA: foreground is attr & 15, background attr >> 4
	tip:     [MAX_NAME_BYTES]u8,
	tip_len: int,
}

Grid :: struct {
	valid: bool, // false until a menu has drawn a room
	cells: [ROOM_ROWS][ROOM_COLS]Cell,
}

cell_tip :: proc(c: ^Cell) -> string {
	return string(c.tip[:c.tip_len])
}

// Elements and prompt text live in the temp allocator or in `Game` messages.
// Draw it before the next transition, then `free_all(context.temp_allocator)`.
View :: struct {
	elements: []Element,
	prompt:   Prompt,
	grid:     ^Grid, // nil when there is no room to show yet
}

Ui :: struct {
	screen:  Screen,
	feature: int, // Feature_Menu
	kind:    Item_Kind, // stack screens
	item:    int, // item screens
	grid:    Grid,
}

// Things a transition may need from outside: the clock and two uniform rolls
// in [0,1) (the sanity bonus on a step, the sponsor pick for an ad break).
Env :: struct {
	now_ms:       i64,
	move_roll:    f64,
	sponsor_roll: f64,
}

TITLE_TEXT :: "Feretory of SPLORR!!"
DEFAULT_NAME :: "Olen Kyrpa"

ui_start :: proc(ui: ^Ui) {
	ui.screen = .Title
}

// ---- the room picture -----------------------------------------------------------

@(private = "file")
set_cell :: proc(c: ^Cell, ch, attr: u8, tip: string) {
	c.ch = ch
	c.attr = attr
	n := min(len(tip), MAX_NAME_BYTES)
	copy(c.tip[:n], tip)
	c.tip_len = n
}

feature_look :: proc(k: Feature_Kind) -> (ch: u8, attr: u8) {
	switch k {
	case .Door:     return '+', 6
	case .Poo_Pile: return '~', 6
	case .Ink_Well: return 'I', 9
	case .Tax_Form: return 'T', 0xF0
	}
	return '?', 7
}

item_look :: proc(k: Item_Kind) -> (ch: u8, attr: u8) {
	switch k {
	case .Food: return 'f', 12
	case .Pen:  return '/', 1
	case .Key:  return 'k', 14
	}
	return '?', 7
}

// Per tile, the first of: character, feature, item on the ground, the tile itself.
refresh_grid :: proc(ui: ^Ui, g: ^Game) {
	ui.grid.valid = true
	room := g.at.room
	for row in 0 ..< ROOM_ROWS {
		for col in 0 ..< ROOM_COLS {
			at := Loc{room, col, row}
			cell := &ui.grid.cells[row][col]
			if has_character(g, at) {
				set_cell(cell, '@', 0xF, g.name)
				continue
			}
			if fs := features_at(g, at); len(fs) > 0 {
				ch, attr := feature_look(g.features[fs[0]].kind)
				set_cell(cell, ch, attr, feature_name(g.features[fs[0]].kind))
				continue
			}
			found := false
			for i in 0 ..< g.item_count {
				if in_container(&g.items[i], .Ground, at) {
					ch, attr := item_look(g.items[i].kind)
					set_cell(cell, ch, attr, item_name(g.items[i].kind))
					found = true
					break
				}
			}
			if found {
				continue
			}
			if is_floor(g, at) {
				set_cell(cell, '.', 0x7, "floor")
			} else {
				set_cell(cell, '#', 0x91, "wall")
			}
		}
	}
}

// ---- choices ------------------------------------------------------------------

@(private = "file")
c :: proc(text: string, action: Action, arg: int = 0) -> Choice {
	return Choice{text = text, action = action, arg = arg}
}

current_choices :: proc(ui: ^Ui, g: ^Game) -> []Choice {
	out := make([dynamic]Choice, context.temp_allocator)
	switch ui.screen {
	case .Title:
		append(&out, c("OK", .Title_Ok))
	case .Main_Menu:
		append(&out, c("Embark!", .Embark)) // Quit is disabled in the browser build
	case .Choose_Name:
	case .Game_Menu:
		append(&out, c("Continue", .Continue), c("Abandon", .Abandon))
	case .Confirm_Abandon:
		append(&out, c("No", .Confirm_No), c("Yes", .Confirm_Yes))
	case .Ad_Menu, .Item_Verb_Done:
		append(&out, c("Ok", .Ok))
	case .Nav_Menu:
		for v in Avatar_Verb {
			if can_perform(g, v) {
				append(&out, c(avatar_verb_name(v), .Avatar_Verb, int(v)))
			}
		}
		// The dead and the insane can only look around and use the menus.
		if can_act(g) {
			if has_items(g, .Ground) {
				append(&out, c("Ground...", .Ground))
			}
			if has_items(g, .Inventory) {
				append(&out, c("Inventory...", .Inventory))
			}
			for fi in features_at(g, g.at) {
				append(&out, c(fmt.tprintf("%s...", feature_name(g.features[fi].kind)), .Feature, fi))
			}
		}
		append(&out, c("Watch Ad...", .Watch_Ad), c("Gämë Mënü", .Game_Menu))
	case .Feature_Menu:
		append(&out, c("Never Mind", .Never_Mind))
		// "Items..." is never shown: features never hold items.
		for v in feature_verbs(g.features[ui.feature].kind) {
			if can_feature_verb(g, ui.feature, v) {
				append(&out, c(feature_verb_name(v), .Feature_Verb, int(v)))
			}
		}
	case .Inventory_Menu:
		append(&out, c("Never Mind", .Never_Mind))
		for s in stacks_in(g, .Inventory) {
			append(&out, c(stack_name(s), .Stack, int(s.kind)))
		}
	case .Ground_Menu:
		append(&out, c("Never Mind", .Never_Mind))
		for s in stacks_in(g, .Ground) {
			append(&out, c(stack_name(s), .Stack, int(s.kind)))
		}
	case .Inventory_Stack_Menu:
		s := stack_of(g, .Inventory, ui.kind)
		append(&out, c("Never Mind", .Never_Mind))
		if s.count > 1 {
			append(&out, c("Drop One", .Drop_Stack, 1))
		}
		if s.count > 3 {
			append(&out, c(fmt.tprintf("Drop Half(%d)", s.count / 2), .Drop_Stack, s.count / 2))
		}
		if s.count > 1 {
			append(&out, c("Drop All", .Drop_Stack, s.count))
		}
		for i in 0 ..< g.item_count {
			if in_container(&g.items[i], .Inventory, g.at) && g.items[i].kind == ui.kind {
				append(&out, c(fmt.tprintf("%s...", item_name(ui.kind)), .Item, i))
			}
		}
	case .Ground_Stack_Menu:
		s := stack_of(g, .Ground, ui.kind)
		append(&out, c("Never Mind", .Never_Mind))
		if s.count > 1 {
			append(&out, c("Take One", .Take_Stack, 1))
		}
		if s.count > 3 {
			append(&out, c(fmt.tprintf("Take Half(%d)", s.count / 2), .Take_Stack, s.count / 2))
		}
		if s.count > 1 {
			append(&out, c("Take All", .Take_Stack, s.count))
		}
		for i in 0 ..< g.item_count {
			if in_container(&g.items[i], .Ground, g.at) && g.items[i].kind == ui.kind {
				append(&out, c(fmt.tprintf("%s...", item_name(ui.kind)), .Item, i))
			}
		}
	case .Inventory_Item_Menu:
		append(&out, c("Never Mind", .Never_Mind), c("Drop", .Drop))
		for v in item_verbs(g.items[ui.item].kind) {
			append(&out, c(item_verb_name(v), .Item_Verb, int(v)))
		}
	case .Ground_Item_Menu:
		append(&out, c("Never Mind", .Never_Mind), c("Take", .Take))
	}
	return out[:]
}

// ---- view -------------------------------------------------------------------------

@(private = "file")
message_elements :: proc(out: ^[dynamic]Element, g: ^Game) {
	for m in g.messages {
		append(out, Element{kind = m.href != "" ? .Link : .Text, text = m.text, href = m.href, new_line = true})
	}
}

// The screens whose original class is a MetaphorPickerMenu: they redraw the
// room and show the message log. The others leave the picture as it was.
@(private = "file")
is_picker :: proc(s: Screen) -> bool {
	switch s {
	case .Title, .Main_Menu, .Choose_Name, .Game_Menu, .Confirm_Abandon:
		return false
	case .Ad_Menu, .Nav_Menu, .Feature_Menu, .Item_Verb_Done, .Inventory_Menu, .Inventory_Stack_Menu,
	     .Inventory_Item_Menu, .Ground_Menu, .Ground_Stack_Menu, .Ground_Item_Menu:
		return true
	}
	return false
}

make_view :: proc(ui: ^Ui, g: ^Game) -> View {
	elements := make([dynamic]Element, context.temp_allocator)
	v: View
	v.prompt.kind = .Choice
	v.prompt.choices = current_choices(ui, g)
	if is_picker(ui.screen) {
		refresh_grid(ui, g)
		message_elements(&elements, g)
	}
	switch ui.screen {
	case .Title:
		append(&elements, Element{kind = .Title, text = TITLE_TEXT})
		append(&elements, Element{kind = .Text, text = "A Production of "})
		append(&elements, Element{kind = .Link, text = "TheGrumpyGameDev", href = "https://thegrumpygamedev.itch.io/", new_line = true})
		append(&elements, Element{kind = .Text, text = "For: ", new_line = true})
		append(&elements, Element{kind = .Link, text = "roguetemple's Fortnight 2", href = "https://itch.io/jam/roguetemples-fortnight-2", new_line = true})
		append(&elements, Element{kind = .Text, text = "Sponsored by: ", new_line = true})
		append(&elements, Element{kind = .Link, text = "UMLAUT.FYI!", href = "https://umlaut.fyi/", new_line = true})
		append(&elements, Element{kind = .Link, text = "Pen 15!", href = "https://pen15.site/", new_line = true})
		append(&elements, Element{kind = .Link, text = "Jargonize!", href = "https://jargonize.app/", new_line = true})
	case .Main_Menu:
		v.prompt.title = "Main Menu:"
	case .Choose_Name:
		v.prompt.kind = .Text
		v.prompt.title = "What is your name?"
		v.prompt.initial = DEFAULT_NAME
	case .Game_Menu:
		v.prompt.title = "Game Menu:"
	case .Confirm_Abandon:
		v.prompt.title = "Are you sure you want to abandon?"
	case .Ad_Menu, .Item_Verb_Done:
	case .Nav_Menu:
		v.prompt.title = "Now What?"
	case .Feature_Menu:
		v.prompt.title = fmt.tprintf("Do what with %s?", feature_name(g.features[ui.feature].kind))
	case .Inventory_Menu:
		v.prompt.title = "Inventory:"
	case .Ground_Menu:
		v.prompt.title = "On the ground:"
	case .Inventory_Stack_Menu, .Ground_Stack_Menu:
		v.prompt.title = "Items in stack:"
	case .Inventory_Item_Menu, .Ground_Item_Menu:
		v.prompt.title = fmt.tprintf("Do what with %s?", item_name(g.items[ui.item].kind))
	}
	v.elements = elements[:]
	if ui.grid.valid {
		v.grid = &ui.grid
	}
	return v
}

// ---- transitions -----------------------------------------------------------------------

// InPlay.Run: an ad break that is still running shows its countdown; one that
// has run out says so, and keeps its Ok button for this screen even though the
// break is already over. Otherwise the navigation menu.
enter_play :: proc(ui: ^Ui, g: ^Game, env: Env) {
	if g.ad_active {
		ad_show(g, env.now_ms, env.sponsor_roll)
		ui.screen = .Ad_Menu
		return
	}
	ui.screen = .Nav_Menu
}

launch_feature_menu :: proc(ui: ^Ui, g: ^Game, env: Env, fi: int) {
	if feature_exists_here(g, fi) {
		clear_messages(g)
		describe_feature(g, fi)
		ui.feature = fi
		ui.screen = .Feature_Menu
		return
	}
	enter_play(ui, g, env)
}

launch_inventory_menu :: proc(ui: ^Ui, g: ^Game, env: Env) {
	if has_items(g, .Inventory) {
		ui.screen = .Inventory_Menu
		return
	}
	enter_play(ui, g, env)
}

// Describing an item normally replaces the log; `keep_log` adds to it instead.
launch_inventory_item :: proc(ui: ^Ui, g: ^Game, ii: int, keep_log := false) {
	if !keep_log {
		clear_messages(g)
	}
	describe_item(g, ii)
	ui.item = ii
	ui.screen = .Inventory_Item_Menu
}

launch_inventory_stack :: proc(ui: ^Ui, g: ^Game, env: Env, kind: Item_Kind, keep_log := false) {
	s := stack_of(g, .Inventory, kind)
	switch s.count {
	case 0:
		launch_inventory_menu(ui, g, env)
	case 1:
		launch_inventory_item(ui, g, s.top, keep_log)
	case:
		ui.kind = kind
		ui.screen = .Inventory_Stack_Menu
	}
}

launch_ground_menu :: proc(ui: ^Ui, g: ^Game, env: Env) {
	if has_items(g, .Ground) {
		ui.screen = .Ground_Menu
		return
	}
	enter_play(ui, g, env)
}

launch_ground_item :: proc(ui: ^Ui, ii: int) {
	ui.item = ii
	ui.screen = .Ground_Item_Menu
}

launch_ground_stack :: proc(ui: ^Ui, g: ^Game, env: Env, kind: Item_Kind) {
	s := stack_of(g, .Ground, kind)
	switch s.count {
	case 0:
		launch_ground_menu(ui, g, env)
	case 1:
		launch_ground_item(ui, s.top)
	case:
		ui.kind = kind
		ui.screen = .Ground_Stack_Menu
	}
}

// Pick choice `index` of the current screen. Out-of-range indexes are ignored.
choose :: proc(ui: ^Ui, g: ^Game, env: Env, index: int) {
	choices := current_choices(ui, g)
	if index < 0 || index >= len(choices) {
		return
	}
	ch := choices[index]
	switch ch.action {
	case .Title_Ok:
		ui.screen = .Main_Menu
	case .Embark:
		ui.screen = .Choose_Name
	case .Continue, .Confirm_No, .Ok:
		enter_play(ui, g, env)
	case .Abandon:
		ui.screen = .Confirm_Abandon
	case .Confirm_Yes:
		abandon(g)
		ui.grid.valid = false // no room to show once the game is gone
		ui.screen = .Main_Menu
	case .Never_Mind:
		#partial switch ui.screen {
		case .Inventory_Stack_Menu, .Inventory_Item_Menu:
			launch_inventory_menu(ui, g, env)
		case .Ground_Stack_Menu, .Ground_Item_Menu:
			launch_ground_menu(ui, g, env)
		case:
			enter_play(ui, g, env)
		}
	case .Avatar_Verb:
		perform(g, Avatar_Verb(ch.arg), env.move_roll)
		enter_play(ui, g, env)
	case .Feature:
		launch_feature_menu(ui, g, env, ch.arg)
	case .Feature_Verb:
		perform_feature_verb(g, ui.feature, Feature_Verb(ch.arg))
		enter_play(ui, g, env)
	case .Item_Verb:
		perform_item_verb(g, ui.item, Item_Verb(ch.arg))
		ui.screen = .Item_Verb_Done
	case .Ground:
		launch_ground_menu(ui, g, env)
	case .Inventory:
		launch_inventory_menu(ui, g, env)
	case .Stack:
		if ui.screen == .Inventory_Menu {
			launch_inventory_stack(ui, g, env, Item_Kind(ch.arg))
		} else {
			launch_ground_stack(ui, g, env, Item_Kind(ch.arg))
		}
	case .Item:
		if ui.screen == .Inventory_Stack_Menu {
			launch_inventory_item(ui, g, ch.arg)
		} else {
			launch_ground_item(ui, ch.arg)
		}
	case .Drop:
		drop_item(g, ui.item)
		launch_inventory_menu(ui, g, env)
	case .Drop_Stack:
		move_stack(g, ui.kind, .Inventory, ch.arg)
		launch_inventory_stack(ui, g, env, ui.kind, keep_log = true) // keep "X drops n food."
	case .Take:
		take_item(g, ui.item)
		launch_ground_menu(ui, g, env)
	case .Take_Stack:
		move_stack(g, ui.kind, .Ground, ch.arg)
		launch_ground_stack(ui, g, env, ui.kind)
	case .Watch_Ad:
		ad_start(g, env.now_ms)
		enter_play(ui, g, env)
	case .Game_Menu:
		ui.screen = .Game_Menu
	}
}

submit_text :: proc(ui: ^Ui, g: ^Game, env: Env, text: string) {
	if ui.screen != .Choose_Name {
		return
	}
	embark(g, text)
	enter_play(ui, g, env)
}
