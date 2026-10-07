#+build !js
package feretory

import "core:math/rand"
import "core:testing"

// Drives the state machine the way a front end would.
Session :: struct {
	g:   ^Game,
	ui:  Ui,
	env: Env,
}

session_start :: proc(seed: u64 = 1) -> Session {
	s: Session
	s.g = new_game(seed)
	ui_start(&s.ui)
	s.env = Env{now_ms = 1_000_000, move_roll = 0.9, sponsor_roll = 0}
	return s
}

session_end :: proc(s: ^Session) {
	free_game(s.g)
}

choice_texts :: proc(s: ^Session) -> []string {
	cs := current_choices(&s.ui, s.g)
	out := make([]string, len(cs), context.temp_allocator)
	for ch, i in cs {
		out[i] = ch.text
	}
	return out
}

// Choose by visible text. Returns false when that choice is not offered.
pick :: proc(s: ^Session, text: string) -> bool {
	for ch, i in current_choices(&s.ui, s.g) {
		if ch.text == text {
			choose(&s.ui, s.g, s.env, i)
			return true
		}
	}
	return false
}

expect_choices :: proc(t: ^testing.T, s: ^Session, want: []string, loc := #caller_location) {
	got := choice_texts(s)
	ok := len(got) == len(want)
	if ok {
		for w, i in want {
			ok &&= got[i] == w
		}
	}
	testing.expectf(t, ok, "choices\n  got  %v\n  want %v", got, want, loc = loc)
}

// Title -> Main Menu -> name -> in play with the generated world.
begin :: proc(t: ^testing.T, s: ^Session) {
	testing.expect(t, pick(s, "OK"))
	testing.expect(t, pick(s, "Embark!"))
	submit_text(&s.ui, s.g, s.env, "Tester")
}

// Begin, then swap the generated world for an empty one the test fills.
begin_bare :: proc(t: ^testing.T, s: ^Session) {
	begin(t, s)
	s.g.feature_count = 0
	s.g.item_count = 0
	s.g.at = Loc{0, 7, 7}
	clear_messages(s.g)
	enter_play(&s.ui, s.g, s.env)
}

// ---- boilerplate screens --------------------------------------------------------------------

@(test)
title_then_main_menu_then_name :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	v := make_view(&s.ui, s.g)
	testing.expect_value(t, s.ui.screen, Screen.Title)
	testing.expect_value(t, v.elements[0].kind, Element_Kind.Title)
	testing.expect_value(t, v.elements[0].text, "Feretory of SPLORR!!")
	testing.expect_value(t, len(v.elements), 9)
	testing.expect(t, v.grid == nil)
	expect_choices(t, &s, {"OK"})

	pick(&s, "OK")
	v = make_view(&s.ui, s.g)
	testing.expect_value(t, v.prompt.title, "Main Menu:")
	expect_choices(t, &s, {"Embark!"})

	pick(&s, "Embark!")
	v = make_view(&s.ui, s.g)
	testing.expect_value(t, v.prompt.kind, Prompt_Kind.Text)
	testing.expect_value(t, v.prompt.title, "What is your name?")
	testing.expect_value(t, v.prompt.initial, "Olen Kyrpa")

	submit_text(&s.ui, s.g, s.env, "Olen")
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)
	testing.expect_value(t, s.g.name, "Olen")
}

@(test)
game_menu_and_abandon :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	begin(t, &s)
	pick(&s, "Gämë Mënü")
	testing.expect_value(t, make_view(&s.ui, s.g).prompt.title, "Game Menu:")
	expect_choices(t, &s, {"Continue", "Abandon"})
	pick(&s, "Continue")
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)

	pick(&s, "Gämë Mënü")
	pick(&s, "Abandon")
	testing.expect_value(t, make_view(&s.ui, s.g).prompt.title, "Are you sure you want to abandon?")
	expect_choices(t, &s, {"No", "Yes"})
	pick(&s, "No")
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)

	pick(&s, "Gämë Mënü")
	pick(&s, "Abandon")
	pick(&s, "Yes")
	testing.expect_value(t, s.ui.screen, Screen.Main_Menu)
	testing.expect(t, !s.g.embarked)
}

@(test)
only_in_play_menus_redraw_the_room :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	testing.expect(t, make_view(&s.ui, s.g).grid == nil)
	begin(t, &s)
	v := make_view(&s.ui, s.g)
	testing.expect(t, v.grid != nil)
	// the avatar is drawn as @ with its name as the tooltip
	found := false
	for row in 0 ..< ROOM_ROWS {
		for col in 0 ..< ROOM_COLS {
			c := &v.grid.cells[row][col]
			if c.ch == '@' {
				found = true
				testing.expect_value(t, c.attr, 0xF)
				testing.expect_value(t, cell_tip(c), "Tester")
				testing.expect_value(t, row, s.g.at.row)
				testing.expect_value(t, col, s.g.at.col)
			}
		}
	}
	testing.expect(t, found)
	// the corner is a wall
	testing.expect_value(t, v.grid.cells[0][0].ch, '#')
	testing.expect_value(t, v.grid.cells[0][0].attr, 0x91)

	// the Game Menu keeps showing the room, but abandoning clears the picture
	pick(&s, "Gämë Mënü")
	testing.expect(t, make_view(&s.ui, s.g).grid != nil)
	pick(&s, "Abandon")
	testing.expect(t, make_view(&s.ui, s.g).grid != nil)
	pick(&s, "Yes")
	v = make_view(&s.ui, s.g)
	testing.expect(t, v.grid == nil)
	testing.expect_value(t, s.ui.screen, Screen.Main_Menu)
}

// ---- navigation menu ------------------------------------------------------------------------------

@(test)
navigation_lists_only_what_is_possible :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	begin_bare(t, &s)
	expect_choices(t, &s, {"N", "E", "S", "W", "Look", "Status", "Watch Ad...", "Gämë Mënü"})

	s.g.stats[.Bowel] = 25
	drop_here(s.g, .Food)
	give(s.g, .Key)
	add_feature(s.g, .Tax_Form, s.g.at)
	add_feature(s.g, .Ink_Well, s.g.at)
	expect_choices(t, &s, {
		"N", "E", "S", "W", "Look", "Status", "Poop!", "Ground...", "Inventory...",
		"Tax Form...", "Ink Well...", "Watch Ad...", "Gämë Mënü",
	})
	testing.expect_value(t, make_view(&s.ui, s.g).prompt.title, "Now What?")

	s.g.stats[.Health] = 0
	expect_choices(t, &s, {"Look", "Status", "Watch Ad...", "Gämë Mënü"})
	s.g.stats[.Health] = 100
	s.g.stats[.Sanity] = 0
	expect_choices(t, &s, {"Look", "Status", "Watch Ad...", "Gämë Mënü"})
}

@(test)
verbs_clear_the_log_and_menus_do_not :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	begin_bare(t, &s)
	add_message(s.g, "old news")
	pick(&s, "Status")
	testing.expect_value(t, s.g.messages[0].text, "Status:")
	add_message(s.g, "keep me")
	drop_here(s.g, .Food)
	pick(&s, "Ground...")
	pick(&s, "Never Mind")
	testing.expect_value(t, s.g.messages[len(s.g.messages) - 1].text, "keep me")
	v := make_view(&s.ui, s.g)
	testing.expect_value(t, v.elements[len(v.elements) - 1].text, "keep me")
}

@(test)
moving_through_the_menu :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	begin_bare(t, &s)
	pick(&s, "E")
	testing.expect_value(t, s.g.at, Loc{0, 8, 7})
	testing.expect_value(t, s.g.messages[0].text, "Tester moves east.")
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)
}

// ---- features -------------------------------------------------------------------------------------------

@(test)
feature_menu_describes_then_offers_verbs :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	begin_bare(t, &s)
	door := add_feature(s.g, .Door, s.g.at)
	s.g.features[door].dest = Loc{1, 3, 4}
	s.g.features[door].locked = true
	add_message(s.g, "old news")

	pick(&s, "door...")
	testing.expect_value(t, s.ui.screen, Screen.Feature_Menu)
	v := make_view(&s.ui, s.g)
	testing.expect_value(t, v.prompt.title, "Do what with door?")
	expect_choices(t, &s, {"Never Mind"}) // locked, and no key
	testing.expect_value(t, len(s.g.messages), 2)
	testing.expect_value(t, s.g.messages[0].text, "This is a door.")
	testing.expect_value(t, s.g.messages[1].text, "door is locked.")

	pick(&s, "Never Mind")
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)

	give(s.g, .Key)
	pick(&s, "door...")
	expect_choices(t, &s, {"Never Mind", "Unlock"})
	pick(&s, "Unlock")
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)
	testing.expect_value(t, s.g.messages[0].text, "Tester unlocks door.")

	pick(&s, "door...")
	expect_choices(t, &s, {"Never Mind", "Enter"})
	pick(&s, "Enter")
	testing.expect_value(t, s.g.at, Loc{1, 3, 4})
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)
}

@(test)
signing_removes_the_form_from_the_menu :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	begin_bare(t, &s)
	form := add_feature(s.g, .Tax_Form, s.g.at)
	s.g.features[form].completeness = TAX_FORM_MAX
	give(s.g, .Pen)
	pick(&s, "Tax Form...")
	expect_choices(t, &s, {"Never Mind", "Sign"})
	pick(&s, "Sign")
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)
	testing.expect(t, !pick(&s, "Tax Form..."))
}

// ---- inventory ----------------------------------------------------------------------------------------------

@(test)
inventory_walks_stacks_items_and_drops :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	begin_bare(t, &s)
	testing.expect(t, !pick(&s, "Inventory..."))
	for _ in 0 ..< 5 {
		give(s.g, .Food)
	}
	give(s.g, .Key)

	pick(&s, "Inventory...")
	testing.expect_value(t, make_view(&s.ui, s.g).prompt.title, "Inventory:")
	expect_choices(t, &s, {"Never Mind", "food(x5)", "key(x1)"})

	pick(&s, "food(x5)")
	testing.expect_value(t, make_view(&s.ui, s.g).prompt.title, "Items in stack:")
	expect_choices(t, &s, {"Never Mind", "Drop One", "Drop Half(2)", "Drop All", "food...", "food...", "food...", "food...", "food..."})

	pick(&s, "Drop Half(2)")
	testing.expect_value(t, s.g.messages[0].text, "Tester drops 2 food.")
	expect_choices(t, &s, {"Never Mind", "Drop One", "Drop All", "food...", "food...", "food..."})
	testing.expect_value(t, stack_of(s.g, .Ground, .Food).count, 2)

	pick(&s, "Drop One")
	testing.expect_value(t, s.g.messages[0].text, "Tester drops 1 food.")
	pick(&s, "Drop One")
	// down to a single food: the item screen describes it, below the drop message
	testing.expect_value(t, s.ui.screen, Screen.Inventory_Item_Menu)
	testing.expect_value(t, len(s.g.messages), 2)
	testing.expect_value(t, s.g.messages[0].text, "Tester drops 1 food.")
	testing.expect_value(t, s.g.messages[1].text, "It is a food.")
	testing.expect_value(t, make_view(&s.ui, s.g).prompt.title, "Do what with food?")
	expect_choices(t, &s, {"Never Mind", "Drop", "Eat"})

	pick(&s, "Drop")
	testing.expect_value(t, s.g.messages[0].text, "Tester drops food.")
	expect_choices(t, &s, {"Never Mind", "key(x1)"})
	testing.expect_value(t, stack_of(s.g, .Ground, .Food).count, 5)

	pick(&s, "key(x1)") // a single item goes straight to its menu
	testing.expect_value(t, s.ui.screen, Screen.Inventory_Item_Menu)
	expect_choices(t, &s, {"Never Mind", "Drop"})
	pick(&s, "Drop") // inventory now empty: back to Now What?
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)
}

@(test)
eating_shows_an_ok_screen :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	begin_bare(t, &s)
	f := give(s.g, .Food)
	s.g.items[f].stomach = 9
	pick(&s, "Inventory...")
	pick(&s, "food(x1)")
	pick(&s, "Eat")
	testing.expect_value(t, s.ui.screen, Screen.Item_Verb_Done)
	expect_choices(t, &s, {"Ok"})
	testing.expect_value(t, s.g.messages[0].text, "Tester gains 9 stomach.")
	v := make_view(&s.ui, s.g)
	testing.expect_value(t, v.prompt.title, "")
	testing.expect_value(t, len(v.elements), 2)
	pick(&s, "Ok")
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)
	testing.expect(t, !pick(&s, "Inventory..."))
}

@(test)
never_mind_goes_back_one_level :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	begin_bare(t, &s)
	give(s.g, .Key)
	give(s.g, .Key)
	pick(&s, "Inventory...")
	pick(&s, "key(x2)")
	testing.expect_value(t, s.ui.screen, Screen.Inventory_Stack_Menu)
	pick(&s, "key...")
	testing.expect_value(t, s.ui.screen, Screen.Inventory_Item_Menu)
	pick(&s, "Never Mind")
	testing.expect_value(t, s.ui.screen, Screen.Inventory_Menu)
	pick(&s, "key(x2)")
	pick(&s, "Never Mind")
	testing.expect_value(t, s.ui.screen, Screen.Inventory_Menu)
	pick(&s, "Never Mind")
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)
}

// ---- ground ---------------------------------------------------------------------------------------------------

@(test)
ground_walks_stacks_and_takes :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	begin_bare(t, &s)
	for _ in 0 ..< 4 {
		drop_here(s.g, .Food)
	}
	drop_here(s.g, .Pen)

	pick(&s, "Ground...")
	testing.expect_value(t, make_view(&s.ui, s.g).prompt.title, "On the ground:")
	expect_choices(t, &s, {"Never Mind", "food(x4)", "Pen #15(x1)"})

	pick(&s, "food(x4)")
	expect_choices(t, &s, {"Never Mind", "Take One", "Take Half(2)", "Take All", "food...", "food...", "food...", "food..."})
	pick(&s, "Take Half(2)")
	testing.expect_value(t, s.g.messages[0].text, "Tester takes 2 food.")
	testing.expect_value(t, stack_of(s.g, .Inventory, .Food).count, 2)
	expect_choices(t, &s, {"Never Mind", "Take One", "Take All", "food...", "food..."})

	pick(&s, "food...")
	testing.expect_value(t, s.ui.screen, Screen.Ground_Item_Menu)
	testing.expect_value(t, make_view(&s.ui, s.g).prompt.title, "Do what with food?")
	expect_choices(t, &s, {"Never Mind", "Take"})
	pick(&s, "Take")
	testing.expect_value(t, s.g.messages[0].text, "Tester takes food.")
	// one food left: the stack screen is gone, the ground menu lists the rest
	testing.expect_value(t, s.ui.screen, Screen.Ground_Menu)
	expect_choices(t, &s, {"Never Mind", "food(x1)", "Pen #15(x1)"})

	pick(&s, "food(x1)")
	testing.expect_value(t, s.ui.screen, Screen.Ground_Item_Menu)
	pick(&s, "Take")
	pick(&s, "Pen #15(x1)")
	pick(&s, "Never Mind")
	testing.expect_value(t, s.ui.screen, Screen.Ground_Menu)
	pick(&s, "Pen #15(x1)")
	pick(&s, "Take") // the ground is empty now: back to Now What?
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)
	testing.expect(t, !pick(&s, "Ground..."))
}

// ---- ads ----------------------------------------------------------------------------------------------------------

@(test)
ad_break_takes_over_play_until_it_runs_out :: proc(t: ^testing.T) {
	s := session_start()
	defer session_end(&s)
	begin_bare(t, &s)
	pick(&s, "Watch Ad...")
	testing.expect_value(t, s.ui.screen, Screen.Ad_Menu)
	expect_choices(t, &s, {"Ok"})
	testing.expect_value(t, s.g.messages[0].text, "Time left in ad break: 02:00")
	testing.expect_value(t, s.g.messages[2].href, "https://umlaut.fyi/")

	s.env.now_ms += 90_000
	pick(&s, "Ok")
	testing.expect_value(t, s.ui.screen, Screen.Ad_Menu)
	testing.expect_value(t, s.g.messages[0].text, "Time left in ad break: 00:30")

	s.env.now_ms += 40_000
	pick(&s, "Ok")
	testing.expect_value(t, s.ui.screen, Screen.Ad_Menu)
	testing.expect_value(t, s.g.messages[0].text, "Ad break is complete! You may return to yer metaphor!")
	testing.expect(t, !s.g.ad_active)
	pick(&s, "Ok")
	testing.expect_value(t, s.ui.screen, Screen.Nav_Menu)
}

// ---- soak ------------------------------------------------------------------------------------------------------------

// Press random buttons for a long time: no crash, no empty menu, stats in range.
@(test)
random_play_never_gets_stuck :: proc(t: ^testing.T) {
	for seed in u64(1) ..= 4 {
		s := session_start(seed)
		defer session_end(&s)
		begin(t, &s)
		for step in 0 ..< 1500 {
			s.env.move_roll = rand.float64()
			s.env.sponsor_roll = rand.float64()
			s.env.now_ms += 20_000
			v := make_view(&s.ui, s.g)
			if len(v.prompt.choices) == 0 {
				testing.expectf(t, false, "seed %d step %d: empty menu on %v", seed, step, s.ui.screen)
				break
			}
			// keep the walk away from abandoning the game
			i := rand.int_max(len(v.prompt.choices))
			if v.prompt.choices[i].action == .Game_Menu {
				continue
			}
			choose(&s.ui, s.g, s.env, i)
			for st in Stat {
				if s.g.stats[st] < 0 || s.g.stats[st] > stat_max[st] {
					testing.expectf(t, false, "seed %d: %v out of range", seed, st)
				}
			}
			free_all(context.temp_allocator)
		}
	}
}
