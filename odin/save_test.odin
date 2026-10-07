#+build !js
package feretory

import "core:strings"
import "core:testing"

// Two games are the same when everything the player can see matches.
same_game :: proc(t: ^testing.T, a, b: ^Game, loc := #caller_location) {
	testing.expect_value(t, a.name, b.name, loc = loc)
	testing.expect_value(t, a.rooms, b.rooms, loc = loc)
	testing.expect_value(t, a.at, b.at, loc = loc)
	testing.expect_value(t, a.stats, b.stats, loc = loc)
	testing.expect_value(t, a.ad_active, b.ad_active, loc = loc)
	testing.expect_value(t, a.ad_finish_ms, b.ad_finish_ms, loc = loc)
	testing.expect_value(t, len(a.messages), len(b.messages), loc = loc)
	for m, i in a.messages {
		if i < len(b.messages) {
			testing.expect_value(t, m.text, b.messages[i].text, loc = loc)
			testing.expect_value(t, m.href, b.messages[i].href, loc = loc)
		}
	}
	// dead slots are not saved, so compare the live things in order
	fa, fb := 0, 0
	for i in 0 ..< a.feature_count {
		if a.features[i].alive {
			for fb < b.feature_count && !b.features[fb].alive {
				fb += 1
			}
			testing.expect(t, fb < b.feature_count, loc = loc)
			if fb < b.feature_count {
				testing.expect_value(t, a.features[i], b.features[fb], loc = loc)
			}
			fb += 1
			fa += 1
		}
	}
	testing.expect_value(t, count_features(a, .Door) + count_features(a, .Tax_Form) + count_features(a, .Ink_Well) + count_features(a, .Poo_Pile), fa, loc = loc)
	ia, ib := 0, 0
	for i in 0 ..< a.item_count {
		if a.items[i].alive {
			for ib < b.item_count && !b.items[ib].alive {
				ib += 1
			}
			testing.expect(t, ib < b.item_count, loc = loc)
			if ib < b.item_count {
				testing.expect_value(t, a.items[i], b.items[ib], loc = loc)
			}
			ib += 1
			ia += 1
		}
	}
	_ = ia
}

@(test)
a_fresh_game_round_trips :: proc(t: ^testing.T) {
	a := new_game(7)
	b := new_game(8)
	defer free_game(a)
	defer free_game(b)
	embark(a, "Tester")
	text := save_to_string(a, context.temp_allocator)
	testing.expect(t, len(text) > 0)
	testing.expect(t, load_from_string(b, text))
	testing.expect(t, b.embarked)
	same_game(t, a, b)
}

@(test)
a_played_game_round_trips :: proc(t: ^testing.T) {
	a := new_game(11)
	b := new_game(12)
	defer free_game(a)
	defer free_game(b)
	embark(a, "Tester")
	// a bit of everything: a taken item, a poo pile, an eaten food, a used key, an ad
	g := a
	for i in 0 ..< g.item_count {
		if g.items[i].kind == .Food {
			g.items[i].place = .Inventory
			break
		}
	}
	g.stats[.Bowel] = 40
	g.stats[.Sanity] = 33
	perform(g, .Poop)
	ad_start(g, 123_456)
	ad_show(g, 124_000, 0.9)
	text := save_to_string(g, context.temp_allocator)
	testing.expect(t, load_from_string(b, text))
	same_game(t, a, b)
	testing.expect_value(t, count_features(b, .Poo_Pile), 1)
}

@(test)
only_the_latest_messages_are_saved :: proc(t: ^testing.T) {
	a := new_game()
	b := new_game(2)
	defer free_game(a)
	defer free_game(b)
	embark(a, "Tester")
	for i in 0 ..< 200 {
		add_message(a, "line %d", i)
	}
	text := save_to_string(a, context.temp_allocator)
	testing.expect(t, load_from_string(b, text))
	testing.expect_value(t, len(b.messages), MAX_SAVED_MESSAGES)
	testing.expect_value(t, b.messages[MAX_SAVED_MESSAGES - 1].text, "line 199")
}

@(test)
abandon_writes_an_empty_marker :: proc(t: ^testing.T) {
	a := new_game()
	b := new_game(2)
	defer free_game(a)
	defer free_game(b)
	text := save_to_string(a, context.temp_allocator) // never embarked
	testing.expect(t, load_from_string(b, text))
	testing.expect(t, !b.embarked) // the marker is accepted and leaves a fresh game
}

rep :: proc(s, old, new: string) -> string {
	r, _ := strings.replace(s, old, new, 1, context.temp_allocator)
	return r
}

@(test)
corrupt_saves_are_refused_and_change_nothing :: proc(t: ^testing.T) {
	a := new_game(3)
	b := new_game(4)
	defer free_game(a)
	defer free_game(b)
	embark(a, "Tester")
	embark(b, "Keeper")
	good := save_to_string(a, context.temp_allocator)

	bad := [?]string{
		"",
		"not json",
		"{}",
		`{"version":2,"embarked":true}`,
		strings.concatenate({good[:len(good) - 5]}, context.temp_allocator), // truncated
		rep(good, `"version":1`, `"version":99`),
		rep(good, `"name":"Tester"`, `"name":""`),
		rep(good, `"at_col":`, `"at_col":99,"x":`),
		rep(good, `"embarked":true`, `"embarked":false`),
	}
	for text, i in bad {
		testing.expectf(t, !load_from_string(b, text), "bad save %d was accepted", i)
		testing.expect_value(t, b.name, "Keeper")
		testing.expect(t, b.embarked)
	}
}

@(test)
impossible_worlds_are_refused :: proc(t: ^testing.T) {
	a := new_game(5)
	b := new_game(6)
	defer free_game(a)
	defer free_game(b)
	embark(a, "Tester")

	// the avatar inside a wall
	a.at = Loc{a.at.room, 0, 0}
	testing.expect(t, !load_from_string(b, save_to_string(a, context.temp_allocator)))
	a.at = Loc{a.at.room, 3, 3}

	// stats out of range
	a.stats[.Bowel] = 51
	testing.expect(t, !load_from_string(b, save_to_string(a, context.temp_allocator)))
	a.stats[.Bowel] = 0
	a.stats[.Sanity] = -1
	testing.expect(t, !load_from_string(b, save_to_string(a, context.temp_allocator)))
	a.stats[.Sanity] = 100

	// a maze that is not a tree
	saved := a.rooms[0]
	a.rooms[0].doors = {}
	testing.expect(t, !load_from_string(b, save_to_string(a, context.temp_allocator)))
	a.rooms[0] = saved

	// an item on a wall tile
	i := add_item(a, .Key, .Ground, Loc{0, 0, 0})
	testing.expect(t, !load_from_string(b, save_to_string(a, context.temp_allocator)))
	a.items[i].alive = false

	// an overfull pen
	p := add_item(a, .Pen, .Inventory, {})
	a.items[p].ink = PEN_INK_MAX + 1
	testing.expect(t, !load_from_string(b, save_to_string(a, context.temp_allocator)))
	a.items[p].alive = false

	// and the untouched world still loads
	a.at = Loc{a.at.room, 3, 3}
	testing.expect(t, load_from_string(b, save_to_string(a, context.temp_allocator)))
}
