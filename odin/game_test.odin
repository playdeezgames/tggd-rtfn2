#+build !js
package feretory

import "core:fmt"
import "core:math/rand"
import "core:testing"

new_game :: proc(seed: u64 = 1) -> ^Game {
	rand.reset(seed)
	return new(Game)
}

free_game :: proc(g: ^Game) {
	game_destroy(g)
	free(g)
	free_all(context.temp_allocator)
}

// An embarked game with the generated maze but nothing in it, the avatar in
// the middle of room 0 and an empty log. For tests that build their own scene.
bare_game :: proc(seed: u64 = 1) -> ^Game {
	g := new_game(seed)
	embark(g, "Tester")
	g.feature_count = 0
	g.item_count = 0
	g.at = Loc{0, 7, 7}
	g.stats = {.Satiety = 100, .Health = 100, .Stomach = 0, .Bowel = 0, .Sanity = 100}
	clear_messages(g)
	return g
}

message_texts :: proc(g: ^Game) -> []string {
	out := make([]string, len(g.messages), context.temp_allocator)
	for m, i in g.messages {
		out[i] = m.text
	}
	return out
}

expect_messages :: proc(t: ^testing.T, g: ^Game, want: []string, loc := #caller_location) {
	got := message_texts(g)
	ok := len(got) == len(want)
	if ok {
		for w, i in want {
			if got[i] != w {
				ok = false
			}
		}
	}
	testing.expectf(t, ok, "messages\n  got  %v\n  want %v", got, want, loc = loc)
}

count_features :: proc(g: ^Game, kind: Feature_Kind) -> int {
	n := 0
	for i in 0 ..< g.feature_count {
		if g.features[i].alive && g.features[i].kind == kind {
			n += 1
		}
	}
	return n
}

count_items :: proc(g: ^Game, kind: Item_Kind) -> int {
	n := 0
	for i in 0 ..< g.item_count {
		if g.items[i].alive && g.items[i].kind == kind {
			n += 1
		}
	}
	return n
}

give :: proc(g: ^Game, kind: Item_Kind) -> int {
	return add_item(g, kind, .Inventory, {})
}

drop_here :: proc(g: ^Game, kind: Item_Kind) -> int {
	return add_item(g, kind, .Ground, g.at)
}

// ---- world generation ------------------------------------------------------------------------

@(test)
generated_world_has_the_documented_shape :: proc(t: ^testing.T) {
	for seed in u64(1) ..= 40 {
		g := new_game(seed)
		defer free_game(g)
		embark(g, "Tester")
		testing.expectf(t, maze_ok(&g.rooms), "seed %d: maze is not a tree", seed)

		dead_ends, doors, locked := 0, 0, 0
		for room in 0 ..< ROOM_COUNT {
			if door_count(g, room) == 1 {
				dead_ends += 1
			}
		}
		for i in 0 ..< g.feature_count {
			f := &g.features[i]
			if f.kind != .Door {
				continue
			}
			doors += 1
			if f.locked {
				locked += 1
			}
			// the door sits on the edge, and leads to a door on the opposite edge
			testing.expect(t, is_floor(g, f.at))
			testing.expect(t, is_floor(g, f.dest))
			back := false
			for j in features_at(g, f.dest) {
				back ||= g.features[j].kind == .Door && g.features[j].dest.room == f.at.room
			}
			testing.expectf(t, back, "seed %d: no door back from %v", seed, f.dest)
			testing.expect_value(t, f.locked, door_count(g, f.dest.room) == 1)
		}
		testing.expect_value(t, doors, 2 * (ROOM_COUNT - 1))
		testing.expect_value(t, locked, dead_ends)
		testing.expect_value(t, count_items(g, .Key), dead_ends)
		testing.expect_value(t, count_items(g, .Food), FOOD_COUNT)
		testing.expect_value(t, count_items(g, .Pen), PEN_COUNT)
		testing.expect_value(t, count_features(g, .Tax_Form), TAX_FORM_COUNT)
		testing.expect_value(t, count_features(g, .Ink_Well), INK_WELL_COUNT)

		for i in 0 ..< g.item_count {
			it := &g.items[i]
			testing.expect(t, is_floor(g, it.at))
			switch it.kind {
			case .Food:
				testing.expect(t, door_count(g, it.at.room) >= 2)
				testing.expect(t, it.stomach >= 4 && it.stomach <= 24)
			case .Key:
				testing.expect(t, door_count(g, it.at.room) >= 2)
			case .Pen:
				testing.expect_value(t, it.ink, PEN_INK_MAX)
			}
		}

		// at most one feature per tile in a fresh world
		for i in 0 ..< g.feature_count {
			testing.expect_value(t, len(features_at(g, g.features[i].at)), 1)
		}

		// the avatar starts on a free floor tile in the roomiest room available
		most := 0
		for room in 0 ..< ROOM_COUNT {
			most = max(most, door_count(g, room))
		}
		testing.expect_value(t, door_count(g, g.at.room), min(most, 4))
		testing.expect(t, is_floor(g, g.at))
		testing.expect(t, !has_features(g, g.at))
		testing.expect_value(t, g.stats[.Health], 100)
		testing.expect_value(t, g.stats[.Bowel], 0)
	}
}

@(test)
embark_greets_and_looks :: proc(t: ^testing.T) {
	g := new_game()
	defer free_game(g)
	embark(g, "Tester")
	got := message_texts(g)
	testing.expect_value(t, got[0], "Welcome to Feretory of SPLORR!!")
	testing.expect_value(t, got[1], "Tester is on floor.")
}

@(test)
room_edges_are_walls_except_doorways :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	for d in Direction {
		dc, dr := door_position(d)
		testing.expect_value(t, is_floor(g, Loc{0, dc, dr}), d in g.rooms[0].doors)
	}
	testing.expect(t, !is_floor(g, Loc{0, 0, 0}))
	testing.expect(t, is_floor(g, Loc{0, 1, 1}))
	testing.expect(t, !is_floor(g, Loc{0, -1, 3}))
	testing.expect(t, !is_floor(g, Loc{0, 15, 3}))
}

// ---- movement and biology --------------------------------------------------------------------------

@(test)
walls_block_movement :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	g.at = Loc{0, 1, 1}
	perform(g, .North)
	expect_messages(t, g, {"Tester cannot move north."})
	testing.expect_value(t, g.at, Loc{0, 1, 1})
	perform(g, .West)
	expect_messages(t, g, {"Tester cannot move west."})
}

@(test)
moving_reports_in_order :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	// full sanity: no bonus roll; empty stomach: starvation rules apply
	perform(g, .East)
	expect_messages(t, g, {
		"Tester moves east.",
		"Tester loses 1 satiety.",
		"Tester now has 99/100 satiety.",
		"Tester is on floor.",
	})
	testing.expect_value(t, g.at, Loc{0, 8, 7})
}

@(test)
moving_may_restore_sanity :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	g.stats[.Sanity] = 50
	perform(g, .East, 0.25)
	got := message_texts(g)
	testing.expect_value(t, got[0], "Tester gains 1 sanity.")
	testing.expect_value(t, got[1], "Tester now has 51/100 sanity.")
	testing.expect_value(t, got[2], "Tester moves east.")
	clear_messages(g)
	perform(g, .East, 0.75)
	testing.expect_value(t, message_texts(g)[0], "Tester moves east.")
	testing.expect_value(t, g.stats[.Sanity], 51)
}

@(test)
digestion_moves_food_to_bowel_and_refills_satiety :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	g.stats[.Stomach] = 10
	g.stats[.Satiety] = 90
	do_biology(g, 1)
	expect_messages(t, g, {
		"Tester loses 1 stomach.",
		"Tester now has 9/50 stomach.",
		"Tester gains 1 bowel.",
		"Tester now has 1/50 bowel.",
		"Tester gains 1 satiety.",
		"Tester now has 91/100 satiety.",
	})
}

@(test)
full_satiety_heals :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	g.stats[.Stomach] = 1
	g.stats[.Health] = 50
	do_biology(g, 1)
	testing.expect_value(t, g.stats[.Health], 51)
	testing.expect_value(t, g.stats[.Satiety], 100)
}

@(test)
full_bowel_hurts :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	g.stats[.Stomach] = 5
	g.stats[.Bowel] = 50
	do_biology(g, 1)
	got := message_texts(g)
	testing.expect_value(t, got[2], "Tester takes damage from having a full bowel!")
	testing.expect_value(t, g.stats[.Health], 99)
	testing.expect_value(t, g.stats[.Bowel], 50)
}

@(test)
starving_costs_health_every_step :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	g.stats[.Satiety] = 0
	for expected in ([?]int{99, 98, 97}) {
		do_biology(g, 1)
		testing.expect_value(t, g.stats[.Satiety], 0)
		testing.expect_value(t, g.stats[.Health], expected)
	}
}

@(test)
the_dead_do_not_digest_or_move :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	g.stats[.Health] = 0
	do_biology(g, 1)
	testing.expect_value(t, g.stats[.Satiety], 100)
	testing.expect(t, !can_perform(g, .North))
	testing.expect(t, !can_perform(g, .Poop))
	testing.expect(t, can_perform(g, .Look))
	testing.expect(t, can_perform(g, .Status))
	look(g)
	expect_messages(t, g, {"Tester is dead."})
}

@(test)
the_insane_cannot_move :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	g.stats[.Sanity] = 0
	testing.expect(t, !can_act(g))
	look(g)
	expect_messages(t, g, {"Tester is insane."})
}

@(test)
change_messages_use_the_requested_amount_even_when_clamped :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	change_stat(g, .Sanity, 10)
	expect_messages(t, g, {"Tester gains 10 sanity.", "Tester now has 100/100 sanity."})
	clear_messages(g)
	change_stat(g, .Sanity, 0)
	expect_messages(t, g, {})
}

// ---- looking, status, poop -------------------------------------------------------------------------

@(test)
look_lists_ground_and_features :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	drop_here(g, .Food)
	add_feature(g, .Tax_Form, g.at)
	add_feature(g, .Ink_Well, g.at)
	perform(g, .Look)
	expect_messages(t, g, {
		"Tester is on floor.",
		"There is stuff on the ground.",
		"Features:",
		"- Tax Form",
		"- Ink Well",
	})
}

@(test)
status_shows_every_stat :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	g.stats[.Stomach] = 7
	perform(g, .Status)
	expect_messages(t, g, {
		"Status:",
		"Stomach: 7/50",
		"Bowel: 0/50",
		"Satiety: 100/100",
		"Health: 100/100",
		"Sanity: 100/100",
	})
}

@(test)
poop_needs_a_half_full_bowel_and_makes_a_pile :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	g.stats[.Bowel] = 24
	testing.expect(t, !can_perform(g, .Poop))
	g.stats[.Bowel] = 27
	testing.expect(t, can_perform(g, .Poop))
	perform(g, .Poop)
	expect_messages(t, g, {"Tester loses 13 bowel.", "Tester now has 14/50 bowel."})
	pile := features_at(g, g.at)[0]
	testing.expect_value(t, g.features[pile].kind, Feature_Kind.Poo_Pile)
	testing.expect_value(t, g.features[pile].poo, 13)
	// a second go adds to the same pile
	g.stats[.Bowel] = 30
	perform(g, .Poop)
	testing.expect_value(t, count_features(g, .Poo_Pile), 1)
	testing.expect_value(t, g.features[pile].poo, 28)
	clear_messages(g)
	describe_feature(g, pile)
	expect_messages(t, g, {"This is a poo pile.", "poo pile has 28 poo."})
}

// ---- features -----------------------------------------------------------------------------------------

@(test)
doors_enter_and_unlock :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	door := add_feature(g, .Door, g.at)
	g.features[door].dest = Loc{1, 3, 4}
	g.features[door].locked = true

	testing.expect(t, !can_feature_verb(g, door, .Enter))
	testing.expect(t, !can_feature_verb(g, door, .Unlock)) // no key
	describe_feature(g, door)
	expect_messages(t, g, {"This is a door.", "door is locked."})

	give(g, .Key)
	give(g, .Key)
	testing.expect(t, can_feature_verb(g, door, .Unlock))
	perform_feature_verb(g, door, .Unlock)
	expect_messages(t, g, {"Tester unlocks door."})
	testing.expect_value(t, count_items(g, .Key), 1) // one key is used up
	testing.expect(t, !can_feature_verb(g, door, .Unlock))
	testing.expect(t, can_feature_verb(g, door, .Enter))

	perform_feature_verb(g, door, .Enter)
	expect_messages(t, g, {"Tester enters door.", "Tester is on floor."})
	testing.expect_value(t, g.at, Loc{1, 3, 4})
}

@(test)
tax_forms_are_filled_out_and_signed :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	form := add_feature(g, .Tax_Form, g.at)
	testing.expect(t, !can_feature_verb(g, form, .Fill_Out)) // no pen
	pen := give(g, .Pen)
	testing.expect(t, can_feature_verb(g, form, .Fill_Out))
	testing.expect(t, !can_feature_verb(g, form, .Sign))

	perform_feature_verb(g, form, .Fill_Out)
	expect_messages(t, g, {
		"Pen #15 loses 1 ink.",
		"Pen #15 now has 19/20 ink.",
		"Tax Form gains 1 completeness.",
		"Tax Form now has 1/100 completeness.",
		"Tester loses 1 sanity.",
		"Tester now has 99/100 sanity.",
	})
	describe_feature(g, form)
	testing.expect_value(t, message_texts(g)[len(g.messages) - 1], "Completeness: 1%")

	// ink runs out before the form is done
	g.items[pen].ink = 0
	testing.expect(t, !can_feature_verb(g, form, .Fill_Out))

	g.features[form].completeness = TAX_FORM_MAX
	g.items[pen].ink = 3
	testing.expect(t, !can_feature_verb(g, form, .Fill_Out))
	testing.expect(t, can_feature_verb(g, form, .Sign))
	g.stats[.Sanity] = 50
	perform_feature_verb(g, form, .Sign)
	expect_messages(t, g, {
		"Tester signs Tax Form.",
		"Pen #15 loses 1 ink.",
		"Pen #15 now has 2/20 ink.",
		"Tester gains 10 sanity.",
		"Tester now has 60/100 sanity.",
	})
	testing.expect_value(t, count_features(g, .Tax_Form), 0)
	testing.expect(t, !feature_exists_here(g, form))
}

@(test)
fill_out_uses_the_first_pen_that_still_has_ink :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	form := add_feature(g, .Tax_Form, g.at)
	empty := give(g, .Pen)
	full := give(g, .Pen)
	g.items[empty].ink = 0
	perform_feature_verb(g, form, .Fill_Out)
	testing.expect_value(t, g.items[empty].ink, 0)
	testing.expect_value(t, g.items[full].ink, PEN_INK_MAX - 1)
}

@(test)
ink_wells_refill_the_first_pen_that_needs_it :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	well := add_feature(g, .Ink_Well, g.at)
	testing.expect(t, !can_feature_verb(g, well, .Refill_Pen))
	full := give(g, .Pen)
	testing.expect(t, !can_feature_verb(g, well, .Refill_Pen))
	low := give(g, .Pen)
	g.items[low].ink = 5
	testing.expect(t, can_feature_verb(g, well, .Refill_Pen))
	perform_feature_verb(g, well, .Refill_Pen)
	expect_messages(t, g, {"Pen #15 gains 15 ink.", "Pen #15 now has 20/20 ink."})
	testing.expect_value(t, g.items[full].ink, PEN_INK_MAX)
	testing.expect_value(t, g.items[low].ink, PEN_INK_MAX)
}

@(test)
ink_wells_get_the_right_article :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	describe_feature(g, add_feature(g, .Ink_Well, g.at))
	expect_messages(t, g, {"This is an Ink Well."})
}

@(test)
verbs_only_work_on_features_here :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	form := add_feature(g, .Tax_Form, Loc{0, 3, 3})
	give(g, .Pen)
	perform_feature_verb(g, form, .Fill_Out)
	testing.expect_value(t, g.features[form].completeness, 0)
}

// ---- items ---------------------------------------------------------------------------------------------

@(test)
items_group_into_stacks_in_order_of_appearance :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	drop_here(g, .Key)
	drop_here(g, .Food)
	drop_here(g, .Key)
	add_item(g, .Food, .Ground, Loc{0, 3, 3}) // elsewhere
	give(g, .Pen)
	ground := stacks_in(g, .Ground)
	testing.expect_value(t, len(ground), 2)
	testing.expect_value(t, ground[0].kind, Item_Kind.Key)
	testing.expect_value(t, ground[0].count, 2)
	testing.expect_value(t, ground[1].kind, Item_Kind.Food)
	testing.expect_value(t, stack_name(ground[0]), "key(x2)")
	testing.expect_value(t, len(stacks_in(g, .Inventory)), 1)
}

@(test)
taking_and_dropping :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	a := drop_here(g, .Food)
	take_item(g, a)
	expect_messages(t, g, {"Tester takes food."})
	testing.expect_value(t, g.items[a].place, Place.Inventory)
	g.at = Loc{0, 8, 8}
	drop_item(g, a)
	expect_messages(t, g, {"Tester drops food."})
	testing.expect_value(t, g.items[a].place, Place.Ground)
	testing.expect_value(t, g.items[a].at, Loc{0, 8, 8})
}

@(test)
stacks_move_in_bulk :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	for _ in 0 ..< 5 {
		drop_here(g, .Food)
	}
	move_stack(g, .Food, .Ground, 3)
	expect_messages(t, g, {"Tester takes 3 food."})
	testing.expect_value(t, stack_of(g, .Ground, .Food).count, 2)
	testing.expect_value(t, stack_of(g, .Inventory, .Food).count, 3)
	move_stack(g, .Food, .Inventory, 99) // capped at what is there
	expect_messages(t, g, {"Tester drops 3 food."})
	testing.expect_value(t, stack_of(g, .Ground, .Food).count, 5)
}

@(test)
eating_fills_the_stomach_and_uses_the_food_up :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	f := give(g, .Food)
	g.items[f].stomach = 12
	describe_item(g, f)
	expect_messages(t, g, {"It is a food."})
	perform_item_verb(g, f, .Eat)
	expect_messages(t, g, {"Tester gains 12 stomach.", "Tester now has 12/50 stomach."})
	testing.expect_value(t, count_items(g, .Food), 0)
}

@(test)
pens_describe_their_ink :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	p := give(g, .Pen)
	g.items[p].ink = 7
	describe_item(g, p)
	expect_messages(t, g, {"It is a Pen #15.", "Ink: 7/20"})
}

// ---- ads --------------------------------------------------------------------------------------------------

@(test)
ad_break_counts_down_then_ends :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	ad_start(g, 1_000_000)
	testing.expect(t, g.ad_active)
	ad_show(g, 1_000_000 + 30_000, 0.0)
	got := message_texts(g)
	testing.expect_value(t, got[0], "Time left in ad break: 01:30")
	testing.expect_value(t, len(got), 3)
	testing.expect_value(t, g.messages[2].href, "https://umlaut.fyi/")
	ad_show(g, 1_000_000 + 30_000, 0.5)
	testing.expect_value(t, g.messages[2].href, "https://pen15.site/")
	ad_show(g, 1_000_000 + 30_000, 0.99)
	testing.expect_value(t, g.messages[2].href, "https://jargonize.app/")
	testing.expect(t, g.ad_active)
	ad_show(g, 1_000_000 + AD_BREAK_MS, 0.0)
	expect_messages(t, g, {"Ad break is complete! You may return to yer metaphor!"})
	testing.expect(t, !g.ad_active)
}

@(test)
abandon_wipes_everything_including_the_ad :: proc(t: ^testing.T) {
	g := bare_game()
	defer free_game(g)
	ad_start(g, 5)
	abandon(g)
	testing.expect(t, !g.embarked)
	testing.expect(t, !g.ad_active)
	testing.expect_value(t, len(g.messages), 0)
	testing.expect_value(t, g.feature_count, 0)
	_ = fmt.tprint()
}
