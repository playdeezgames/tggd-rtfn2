package feretory

// Save and load as JSON text. Pure: the page stores the text. Everything the
// player can see is saved (the original never saved at all), so a reload
// resumes exactly where they were, in the navigation menu. Loading validates
// every field; anything odd is refused and the caller starts a fresh game.

import "core:encoding/json"
import "core:strings"

SAVE_KEY :: "feretory:save"
SAVE_VERSION :: 1

MAX_SAVED_MESSAGES :: 64
MAX_MESSAGE_BYTES :: 512

@(private = "file")
Save_Message :: struct {
	text: string,
	href: string,
}

@(private = "file")
Save_Feature :: struct {
	kind:         int,
	room:         int,
	col:          int,
	row:          int,
	dest_room:    int,
	dest_col:     int,
	dest_row:     int,
	locked:       bool,
	completeness: int,
	poo:          int,
}

@(private = "file")
Save_Item :: struct {
	kind:    int,
	place:   int,
	room:    int,
	col:     int,
	row:     int,
	stomach: int,
	ink:     int,
}

// Enums are stored as their integer values and range-checked on load, because
// unknown enum names would unmarshal silently. A room's doors are a 4-bit mask
// (bit n is Direction n).
@(private = "file")
Save_Data :: struct {
	version:      int,
	empty:        bool, // Abandon writes this marker instead of removing the key
	embarked:     bool,
	name:         string,
	doors:        []int,
	at_room:      int,
	at_col:       int,
	at_row:       int,
	stats:        []int, // in Stat order
	features:     []Save_Feature,
	items:        []Save_Item,
	ad_active:    bool,
	ad_finish_ms: i64,
	messages:     []Save_Message,
}

// Text for the page to store. Caller frees with `delete`.
save_to_string :: proc(g: ^Game, allocator := context.allocator) -> string {
	d := Save_Data{version = SAVE_VERSION}
	if !g.embarked {
		d.empty = true
		return marshal_save(&d, allocator)
	}
	d.embarked = true
	d.name = g.name
	doors := make([]int, ROOM_COUNT, context.temp_allocator)
	for room in 0 ..< ROOM_COUNT {
		for dir in Direction {
			if dir in g.rooms[room].doors {
				doors[room] |= 1 << uint(dir)
			}
		}
	}
	d.doors = doors
	d.at_room, d.at_col, d.at_row = g.at.room, g.at.col, g.at.row
	stats := make([]int, len(Stat), context.temp_allocator)
	for s in Stat {
		stats[int(s)] = g.stats[s]
	}
	d.stats = stats

	features := make([dynamic]Save_Feature, context.temp_allocator)
	for i in 0 ..< g.feature_count {
		f := &g.features[i]
		if !f.alive {
			continue
		}
		append(&features, Save_Feature{
			kind = int(f.kind), room = f.at.room, col = f.at.col, row = f.at.row,
			dest_room = f.dest.room, dest_col = f.dest.col, dest_row = f.dest.row,
			locked = f.locked, completeness = f.completeness, poo = f.poo,
		})
	}
	d.features = features[:]
	items := make([dynamic]Save_Item, context.temp_allocator)
	for i in 0 ..< g.item_count {
		it := &g.items[i]
		if !it.alive {
			continue
		}
		append(&items, Save_Item{
			kind = int(it.kind), place = int(it.place), room = it.at.room, col = it.at.col, row = it.at.row,
			stomach = it.stomach, ink = it.ink,
		})
	}
	d.items = items[:]
	d.ad_active = g.ad_active
	d.ad_finish_ms = g.ad_finish_ms

	first := max(0, len(g.messages) - MAX_SAVED_MESSAGES)
	msgs := make([]Save_Message, len(g.messages) - first, context.temp_allocator)
	for m, i in g.messages[first:] {
		msgs[i] = Save_Message{text = m.text, href = m.href}
	}
	d.messages = msgs
	return marshal_save(&d, allocator)
}

@(private = "file")
marshal_save :: proc(d: ^Save_Data, allocator := context.allocator) -> string {
	data, err := json.marshal(d^, {}, allocator)
	if err != nil {
		return ""
	}
	return string(data)
}

@(private = "file")
valid_text :: proc(s: string, max_bytes: int) -> bool {
	return len(s) <= max_bytes
}

@(private = "file")
loc_ok :: proc(rooms: ^[ROOM_COUNT]Room, room, col, row: int) -> bool {
	return floor_in(rooms, Loc{room, col, row})
}

// The doors must form one tree over all rooms, as the generator makes: every
// door has a matching door on the other side and the rooms are all connected.
maze_ok :: proc(rooms: ^[ROOM_COUNT]Room) -> bool {
	edges := 0
	for room in 0 ..< ROOM_COUNT {
		for d in Direction {
			if d not_in rooms[room].doors {
				continue
			}
			n, ok := neighbor_room(room, d)
			if !ok || opposite(d) not_in rooms[n].doors {
				return false
			}
			edges += 1
		}
	}
	if edges != 2 * (ROOM_COUNT - 1) {
		return false
	}
	seen: [ROOM_COUNT]bool
	stack: [ROOM_COUNT]int
	top := 0
	stack[0] = 0
	top = 1
	seen[0] = true
	reached := 1
	for top > 0 {
		top -= 1
		room := stack[top]
		for d in Direction {
			if d in rooms[room].doors {
				n, _ := neighbor_room(room, d)
				if !seen[n] {
					seen[n] = true
					reached += 1
					stack[top] = n
					top += 1
				}
			}
		}
	}
	return reached == ROOM_COUNT
}

// Fills `g` from saved text. Returns false and leaves `g` untouched when the
// text is missing, corrupt, from another version or fails validation.
// A valid "empty" marker loads fine and leaves `g` not embarked.
load_from_string :: proc(g: ^Game, text: string) -> bool {
	if len(text) == 0 {
		return false
	}
	d: Save_Data
	// The parsed form is thrown away with the temp allocator.
	if err := json.unmarshal_string(text, &d, allocator = context.temp_allocator); err != nil {
		return false
	}
	if d.version != SAVE_VERSION {
		return false
	}
	if d.empty {
		return !d.embarked
	}
	if !d.embarked {
		return false
	}
	if len(d.name) == 0 || !valid_text(d.name, MAX_NAME_BYTES) {
		return false
	}

	// maze
	if len(d.doors) != ROOM_COUNT {
		return false
	}
	rooms: [ROOM_COUNT]Room
	for mask, room in d.doors {
		if mask < 0 || mask > 15 {
			return false
		}
		for dir in Direction {
			if mask & (1 << uint(dir)) != 0 {
				rooms[room].doors += {dir}
			}
		}
	}
	if !maze_ok(&rooms) {
		return false
	}

	// avatar
	if !loc_ok(&rooms, d.at_room, d.at_col, d.at_row) {
		return false
	}
	if len(d.stats) != len(Stat) {
		return false
	}
	for s in Stat {
		if d.stats[int(s)] < 0 || d.stats[int(s)] > stat_max[s] {
			return false
		}
	}

	// features and items
	if len(d.features) > MAX_FEATURES || len(d.items) > MAX_ITEMS {
		return false
	}
	for f in d.features {
		if f.kind < int(min(Feature_Kind)) || f.kind > int(max(Feature_Kind)) {
			return false
		}
		if !loc_ok(&rooms, f.room, f.col, f.row) {
			return false
		}
		if Feature_Kind(f.kind) == .Door && !loc_ok(&rooms, f.dest_room, f.dest_col, f.dest_row) {
			return false
		}
		if f.completeness < 0 || f.completeness > TAX_FORM_MAX || f.poo < 0 || f.poo > 1_000_000_000 {
			return false
		}
	}
	for it in d.items {
		if it.kind < int(min(Item_Kind)) || it.kind > int(max(Item_Kind)) {
			return false
		}
		if it.place < int(min(Place)) || it.place > int(max(Place)) {
			return false
		}
		if Place(it.place) == .Ground && !loc_ok(&rooms, it.room, it.col, it.row) {
			return false
		}
		if it.stomach < 0 || it.stomach > 1000 || it.ink < 0 || it.ink > PEN_INK_MAX {
			return false
		}
	}

	// ads and messages
	if d.ad_finish_ms < 0 {
		return false
	}
	if len(d.messages) > MAX_SAVED_MESSAGES {
		return false
	}
	for m in d.messages {
		if !valid_text(m.text, MAX_MESSAGE_BYTES) || !valid_text(m.href, MAX_MESSAGE_BYTES) {
			return false
		}
	}

	// Everything checks out: commit.
	abandon(g)
	g.embarked = true
	g.name = strings.clone(d.name)
	g.rooms = rooms
	g.at = Loc{d.at_room, d.at_col, d.at_row}
	for s in Stat {
		g.stats[s] = d.stats[int(s)]
	}
	for f in d.features {
		i := add_feature(g, Feature_Kind(f.kind), Loc{f.room, f.col, f.row})
		g.features[i].dest = Loc{f.dest_room, f.dest_col, f.dest_row}
		g.features[i].locked = f.locked
		g.features[i].completeness = f.completeness
		g.features[i].poo = f.poo
	}
	for it in d.items {
		i := g.item_count
		g.items[i] = Item{
			alive = true, kind = Item_Kind(it.kind), place = Place(it.place),
			at = Loc{it.room, it.col, it.row}, stomach = it.stomach, ink = it.ink,
		}
		g.item_count += 1
	}
	g.ad_active = d.ad_active
	g.ad_finish_ms = d.ad_finish_ms
	for m in d.messages {
		append(&g.messages, Message{text = strings.clone(m.text), href = strings.clone(m.href)})
	}
	return true
}
