package feretory

// Pure game rules and world generation. No browser imports, so everything here
// runs under `odin test`. Ported from the VB.NET game in ../src
// (see ../docs/PORT_PLAN.md for the verified behavior).

import "core:fmt"
import "core:math/rand"
import "core:strings"

MAZE_COLS :: 5
MAZE_ROWS :: 4
ROOM_COUNT :: MAZE_COLS * MAZE_ROWS
ROOM_COLS :: 15
ROOM_ROWS :: 15

// A poo pile can sit on every tile (4500) on top of the ~70 generated features.
MAX_FEATURES :: 4608
MAX_ITEMS :: 512
MAX_NAME_BYTES :: 64
AD_BREAK_MS :: i64(2 * 60 * 1000)
PEN_INK_MAX :: 20
TAX_FORM_MAX :: 100

FOOD_COUNT :: 100
TAX_FORM_COUNT :: 25
PEN_COUNT :: 5
INK_WELL_COUNT :: 5
MAX_SPAWN_TRIES :: 100_000

Direction :: enum {
	North,
	East,
	South,
	West,
}

Stat :: enum {
	Satiety,
	Health,
	Stomach,
	Bowel,
	Sanity,
}

stat_max := [Stat]int{.Satiety = 100, .Health = 100, .Stomach = 50, .Bowel = 50, .Sanity = 100}
stat_label := [Stat]string{.Satiety = "satiety", .Health = "health", .Stomach = "stomach", .Bowel = "bowel", .Sanity = "sanity"}

Feature_Kind :: enum {
	Door,
	Ink_Well,
	Poo_Pile,
	Tax_Form,
}

Item_Kind :: enum {
	Food,
	Key,
	Pen,
}

Place :: enum {
	Ground,
	Inventory,
}

// The avatar's own verbs, in the order the menu lists them.
Avatar_Verb :: enum {
	North,
	East,
	South,
	West,
	Look,
	Status,
	Poop,
}

Feature_Verb :: enum {
	Enter,
	Unlock,
	Fill_Out,
	Sign,
	Refill_Pen,
}

Item_Verb :: enum {
	Eat,
}

// A tile: which maze room, then the column and row inside the room.
Loc :: struct {
	room, col, row: int,
}

Room :: struct {
	doors: bit_set[Direction],
}

Feature :: struct {
	alive:        bool,
	kind:         Feature_Kind,
	at:           Loc,
	dest:         Loc, // doors only
	locked:       bool,
	completeness: int, // tax forms
	poo:          int, // poo piles
}

Item :: struct {
	alive:   bool,
	kind:    Item_Kind,
	place:   Place,
	at:      Loc, // only while on the ground
	stomach: int, // food
	ink:     int, // pens
}

Message :: struct {
	text: string,
	href: string, // non-empty for a link
}

Game :: struct {
	embarked:      bool,
	name:          string,
	rooms:         [ROOM_COUNT]Room,
	at:            Loc,
	stats:         [Stat]int,
	features:      [MAX_FEATURES]Feature,
	feature_count: int,
	items:         [MAX_ITEMS]Item,
	item_count:    int,
	ad_active:     bool,
	ad_finish_ms:  i64, // wall clock, ms since the epoch
	messages:      [dynamic]Message,
}

game_destroy :: proc(g: ^Game) {
	clear_messages(g)
	delete(g.messages)
	delete(g.name)
	g^ = {}
}

// ---- messages ------------------------------------------------------------

clear_messages :: proc(g: ^Game) {
	for m in g.messages {
		delete(m.text)
		delete(m.href)
	}
	clear(&g.messages)
}

add_message :: proc(g: ^Game, format: string, args: ..any) {
	append(&g.messages, Message{text = fmt.aprintf(format, ..args)})
}

add_link :: proc(g: ^Game, text, href: string) {
	append(&g.messages, Message{text = strings.clone(text), href = strings.clone(href)})
}

// ---- geometry ---------------------------------------------------------------

room_index :: proc(col, row: int) -> int {
	return col * MAZE_ROWS + row
}

room_col :: proc(room: int) -> int {
	return room / MAZE_ROWS
}

room_row :: proc(room: int) -> int {
	return room % MAZE_ROWS
}

direction_delta :: proc(d: Direction) -> (dx, dy: int) {
	switch d {
	case .North: return 0, -1
	case .East:  return 1, 0
	case .South: return 0, 1
	case .West:  return -1, 0
	}
	return 0, 0
}

opposite :: proc(d: Direction) -> Direction {
	switch d {
	case .North: return .South
	case .East:  return .West
	case .South: return .North
	case .West:  return .East
	}
	return d
}

direction_name :: proc(d: Direction) -> string {
	switch d {
	case .North: return "north"
	case .East:  return "east"
	case .South: return "south"
	case .West:  return "west"
	}
	return ""
}

// The neighbouring maze room, if there is one.
neighbor_room :: proc(room: int, d: Direction) -> (int, bool) {
	dx, dy := direction_delta(d)
	c, r := room_col(room) + dx, room_row(room) + dy
	if c < 0 || r < 0 || c >= MAZE_COLS || r >= MAZE_ROWS {
		return 0, false
	}
	return room_index(c, r), true
}

// Where a door in direction d sits on the room's edge.
door_position :: proc(d: Direction) -> (col, row: int) {
	switch d {
	case .North: return ROOM_COLS / 2, 0
	case .East:  return ROOM_COLS - 1, ROOM_ROWS / 2
	case .South: return ROOM_COLS / 2, ROOM_ROWS - 1
	case .West:  return 0, ROOM_ROWS / 2
	}
	return 0, 0
}

// Where you arrive after going through a door in direction d: the opposite edge.
door_destination :: proc(d: Direction) -> (col, row: int) {
	switch d {
	case .North: return ROOM_COLS / 2, ROOM_ROWS - 1
	case .East:  return 0, ROOM_ROWS / 2
	case .South: return ROOM_COLS / 2, 0
	case .West:  return ROOM_COLS - 1, ROOM_ROWS / 2
	}
	return 0, 0
}

door_count :: proc(g: ^Game, room: int) -> int {
	return card(g.rooms[room].doors)
}

in_room :: proc(col, row: int) -> bool {
	return col >= 0 && row >= 0 && col < ROOM_COLS && row < ROOM_ROWS
}

// Room borders are walls, except where the maze opened a door.
is_floor :: proc(g: ^Game, at: Loc) -> bool {
	return floor_in(&g.rooms, at)
}

floor_in :: proc(rooms: ^[ROOM_COUNT]Room, at: Loc) -> bool {
	if at.room < 0 || at.room >= ROOM_COUNT || !in_room(at.col, at.row) {
		return false
	}
	if at.col != 0 && at.row != 0 && at.col != ROOM_COLS - 1 && at.row != ROOM_ROWS - 1 {
		return true
	}
	for d in Direction {
		if d in rooms[at.room].doors {
			dc, dr := door_position(d)
			if dc == at.col && dr == at.row {
				return true
			}
		}
	}
	return false
}

// ---- names -----------------------------------------------------------------------

feature_name :: proc(k: Feature_Kind) -> string {
	switch k {
	case .Door:     return "door"
	case .Ink_Well: return "Ink Well"
	case .Poo_Pile: return "poo pile"
	case .Tax_Form: return "Tax Form"
	}
	return ""
}

item_name :: proc(k: Item_Kind) -> string {
	switch k {
	case .Food: return "food"
	case .Key:  return "key"
	case .Pen:  return "Pen #15"
	}
	return ""
}

avatar_verb_name :: proc(v: Avatar_Verb) -> string {
	switch v {
	case .North:  return "N"
	case .East:   return "E"
	case .South:  return "S"
	case .West:   return "W"
	case .Look:   return "Look"
	case .Status: return "Status"
	case .Poop:   return "Poop!"
	}
	return ""
}

feature_verb_name :: proc(v: Feature_Verb) -> string {
	switch v {
	case .Enter:      return "Enter"
	case .Unlock:     return "Unlock"
	case .Fill_Out:   return "Fill Out"
	case .Sign:       return "Sign"
	case .Refill_Pen: return "Refill Pen"
	}
	return ""
}

item_verb_name :: proc(v: Item_Verb) -> string {
	switch v {
	case .Eat: return "Eat"
	}
	return ""
}

@(private = "file")
door_verbs := [?]Feature_Verb{.Enter, .Unlock}
@(private = "file")
tax_form_verbs := [?]Feature_Verb{.Fill_Out, .Sign}
@(private = "file")
ink_well_verbs := [?]Feature_Verb{.Refill_Pen}
@(private = "file")
food_verbs := [?]Item_Verb{.Eat}

// The verbs a kind of feature carries, in menu order.
feature_verbs :: proc(k: Feature_Kind) -> []Feature_Verb {
	switch k {
	case .Door:     return door_verbs[:]
	case .Tax_Form: return tax_form_verbs[:]
	case .Ink_Well: return ink_well_verbs[:]
	case .Poo_Pile: return nil
	}
	return nil
}

item_verbs :: proc(k: Item_Kind) -> []Item_Verb {
	if k == .Food {
		return food_verbs[:]
	}
	return nil
}

// ---- lookups ----------------------------------------------------------------------------

// Indexes of the live features on a tile, in creation order.
features_at :: proc(g: ^Game, at: Loc, allocator := context.temp_allocator) -> []int {
	out := make([dynamic]int, allocator)
	for i in 0 ..< g.feature_count {
		f := &g.features[i]
		if f.alive && f.at == at {
			append(&out, i)
		}
	}
	return out[:]
}

has_features :: proc(g: ^Game, at: Loc) -> bool {
	for i in 0 ..< g.feature_count {
		f := &g.features[i]
		if f.alive && f.at == at {
			return true
		}
	}
	return false
}

// The avatar is the only character in the game.
has_character :: proc(g: ^Game, at: Loc) -> bool {
	return g.embarked && g.at == at
}

feature_exists_here :: proc(g: ^Game, fi: int) -> bool {
	return fi >= 0 && fi < g.feature_count && g.features[fi].alive && g.features[fi].at == g.at
}

in_container :: proc(it: ^Item, place: Place, at: Loc) -> bool {
	return it.alive && it.place == place && (place == .Inventory || it.at == at)
}

// Indexes of the items in a container (the ground of the avatar's tile, or the inventory).
items_in :: proc(g: ^Game, place: Place, allocator := context.temp_allocator) -> []int {
	out := make([dynamic]int, allocator)
	for i in 0 ..< g.item_count {
		if in_container(&g.items[i], place, g.at) {
			append(&out, i)
		}
	}
	return out[:]
}

has_items :: proc(g: ^Game, place: Place) -> bool {
	for i in 0 ..< g.item_count {
		if in_container(&g.items[i], place, g.at) {
			return true
		}
	}
	return false
}

Stack :: struct {
	kind:  Item_Kind,
	count: int,
	top:   int, // index of the first item of this kind
}

// Items grouped by kind, in order of first appearance.
stacks_in :: proc(g: ^Game, place: Place, allocator := context.temp_allocator) -> []Stack {
	out := make([dynamic]Stack, allocator)
	outer: for i in 0 ..< g.item_count {
		if !in_container(&g.items[i], place, g.at) {
			continue
		}
		for &s in out {
			if s.kind == g.items[i].kind {
				s.count += 1
				continue outer
			}
		}
		append(&out, Stack{kind = g.items[i].kind, count = 1, top = i})
	}
	return out[:]
}

stack_of :: proc(g: ^Game, place: Place, kind: Item_Kind) -> Stack {
	for s in stacks_in(g, place) {
		if s.kind == kind {
			return s
		}
	}
	return Stack{kind = kind}
}

stack_name :: proc(s: Stack) -> string {
	return fmt.tprintf("%s(x%d)", item_name(s.kind), s.count)
}

// ---- stats ----------------------------------------------------------------------------------

is_dead :: proc(g: ^Game) -> bool {
	return g.stats[.Health] == 0
}

is_insane :: proc(g: ^Game) -> bool {
	return g.stats[.Sanity] == 0
}

can_act :: proc(g: ^Game) -> bool {
	return !is_dead(g) && !is_insane(g)
}

// DoChangeCounter: announce the requested change, apply it clamped, announce the result.
report_change :: proc(g: ^Game, owner, label: string, value: ^int, vmax, delta: int) {
	if delta == 0 {
		return
	}
	add_message(g, "%s %s %d %s.", owner, delta > 0 ? "gains" : "loses", abs(delta), label)
	value^ = clamp(value^ + delta, 0, vmax)
	add_message(g, "%s now has %d/%d %s.", owner, value^, vmax, label)
}

change_stat :: proc(g: ^Game, s: Stat, delta: int) {
	report_change(g, g.name, stat_label[s], &g.stats[s], stat_max[s], delta)
}

// One step of the avatar's body: digest, spend food, take damage when starving.
do_biology :: proc(g: ^Game, amount_in: int) {
	amount := amount_in
	if is_dead(g) || amount <= 0 {
		return
	}
	stomach := min(amount, g.stats[.Stomach])
	damage := 0
	if stomach > 0 {
		amount -= stomach
		change_stat(g, .Stomach, -stomach)
		bowel := min(stomach, stat_max[.Bowel] - g.stats[.Bowel])
		damage += stomach - bowel
		if damage > 0 {
			add_message(g, "%s takes damage from having a full bowel!", g.name)
		}
		change_stat(g, .Bowel, bowel)
	}
	satiety := min(amount, g.stats[.Satiety])
	if satiety > 0 {
		amount -= satiety
		change_stat(g, .Satiety, -satiety)
	} else if amount == 0 {
		// The step was paid for by digesting food: restore satiety, or heal once it is full.
		if g.stats[.Satiety] == stat_max[.Satiety] {
			if g.stats[.Health] != stat_max[.Health] && damage <= 0 {
				change_stat(g, .Health, 1)
			}
		} else {
			change_stat(g, .Satiety, 1)
		}
	}
	// Otherwise the avatar is starving: the whole step becomes damage below.
	damage += amount
	if damage > 0 {
		change_stat(g, .Health, -damage)
	}
}

// ---- lifecycle ------------------------------------------------------------------------------------

// Wipes the world. Like the original's Clear, this also ends any ad break.
abandon :: proc(g: ^Game) {
	clear_messages(g)
	delete(g.name)
	g.embarked = false
	g.name = ""
	g.rooms = {}
	g.at = {}
	g.stats = {}
	g.feature_count = 0
	g.item_count = 0
	g.ad_active = false
	g.ad_finish_ms = 0
}

embark :: proc(g: ^Game, name: string) {
	abandon(g)
	g.embarked = true
	g.name = strings.clone(name)
	generate_world(g)
	add_message(g, "Welcome to Feretory of SPLORR!!")
	look(g)
}

// ---- world generation ----------------------------------------------------------------------------------

add_feature :: proc(g: ^Game, kind: Feature_Kind, at: Loc) -> int {
	if g.feature_count >= MAX_FEATURES {
		return -1
	}
	i := g.feature_count
	g.features[i] = Feature{alive = true, kind = kind, at = at}
	g.feature_count += 1
	return i
}

add_item :: proc(g: ^Game, kind: Item_Kind, place: Place, at: Loc) -> int {
	if g.item_count >= MAX_ITEMS {
		return -1
	}
	i := g.item_count
	g.items[i] = Item{alive = true, kind = kind, place = place, at = at}
	switch kind {
	case .Food:
		// 4d6
		g.items[i].stomach = 0
		for _ in 0 ..< 4 {
			g.items[i].stomach += rand.int_max(6) + 1
		}
	case .Pen:
		g.items[i].ink = PEN_INK_MAX
	case .Key:
	}
	g.item_count += 1
	return i
}

// Randomized Prim: grow from a random room, opening a door from each newly
// reached room to a random neighbour that is already part of the maze.
generate_maze :: proc(g: ^Game) {
	for &r in g.rooms {
		r = {}
	}
	inside: [ROOM_COUNT]bool
	in_frontier: [ROOM_COUNT]bool
	frontier: [ROOM_COUNT]int
	frontier_count := 0

	push_neighbors :: proc(room: int, inside, in_frontier: ^[ROOM_COUNT]bool, frontier: ^[ROOM_COUNT]int, count: ^int) {
		for d in Direction {
			if n, ok := neighbor_room(room, d); ok && !inside[n] && !in_frontier[n] {
				in_frontier[n] = true
				frontier[count^] = n
				count^ += 1
			}
		}
	}

	start := rand.int_max(ROOM_COUNT)
	inside[start] = true
	push_neighbors(start, &inside, &in_frontier, &frontier, &frontier_count)
	for frontier_count > 0 {
		pick := rand.int_max(frontier_count)
		room := frontier[pick]
		for i in pick ..< frontier_count - 1 {
			frontier[i] = frontier[i + 1]
		}
		frontier_count -= 1
		in_frontier[room] = false

		options: [4]Direction
		option_count := 0
		for d in Direction {
			if n, ok := neighbor_room(room, d); ok && inside[n] {
				options[option_count] = d
				option_count += 1
			}
		}
		d := options[rand.int_max(option_count)]
		n, _ := neighbor_room(room, d)
		g.rooms[room].doors += {d}
		g.rooms[n].doors += {opposite(d)}
		inside[room] = true
		push_neighbors(room, &inside, &in_frontier, &frontier, &frontier_count)
	}
}

// A door feature in every open doorway; doors into a dead end start locked.
create_doors :: proc(g: ^Game) {
	for room in 0 ..< ROOM_COUNT {
		for d in Direction {
			if d not_in g.rooms[room].doors {
				continue
			}
			next, _ := neighbor_room(room, d)
			col, row := door_position(d)
			fi := add_feature(g, .Door, Loc{room, col, row})
			if fi < 0 {
				continue
			}
			dc, dr := door_destination(d)
			g.features[fi].dest = Loc{next, dc, dr}
			g.features[fi].locked = door_count(g, next) == 1
		}
	}
}

// Floor tiles of a room that hold no feature and no character.
free_floor_tiles :: proc(g: ^Game, room: int, allocator := context.temp_allocator) -> []Loc {
	out := make([dynamic]Loc, allocator)
	for col in 0 ..< ROOM_COLS {
		for row in 0 ..< ROOM_ROWS {
			at := Loc{room, col, row}
			if is_floor(g, at) && !has_features(g, at) && !has_character(g, at) {
				append(&out, at)
			}
		}
	}
	return out[:]
}

Spawner :: enum {
	Food,
	Tax_Form,
	Pen,
	Ink_Well,
}

// Tries one tile; true when the thing was placed.
try_spawn :: proc(g: ^Game, s: Spawner, at: Loc) -> bool {
	if !is_floor(g, at) {
		return false
	}
	switch s {
	case .Food:
		if door_count(g, at.room) < 2 || has_features(g, at) || has_character(g, at) {
			return false
		}
		add_item(g, .Food, .Ground, at)
	case .Tax_Form:
		if has_features(g, at) {
			return false
		}
		add_feature(g, .Tax_Form, at)
	case .Pen:
		add_item(g, .Pen, .Ground, at)
	case .Ink_Well:
		if has_features(g, at) {
			return false
		}
		add_feature(g, .Ink_Well, at)
	}
	return true
}

populate :: proc(g: ^Game, s: Spawner, count: int) {
	for _ in 0 ..< count {
		for _ in 0 ..< MAX_SPAWN_TRIES {
			at := Loc{rand.int_max(ROOM_COUNT), rand.int_max(ROOM_COLS), rand.int_max(ROOM_ROWS)}
			if try_spawn(g, s, at) {
				break
			}
		}
	}
}

// One key per dead-end room, each in a random room that has several doors.
populate_keys :: proc(g: ^Game) {
	dead_ends := 0
	roomy := make([dynamic]int, context.temp_allocator)
	for room in 0 ..< ROOM_COUNT {
		switch door_count(g, room) {
		case 1: dead_ends += 1
		case:   append(&roomy, room)
		}
	}
	// A room with no doors cannot exist: the maze joins every room.
	for _ in 0 ..< dead_ends {
		if len(roomy) == 0 {
			break
		}
		room := roomy[rand.int_max(len(roomy))]
		tiles := free_floor_tiles(g, room)
		if len(tiles) == 0 {
			continue
		}
		add_item(g, .Key, .Ground, tiles[rand.int_max(len(tiles))])
	}
}

// The avatar starts in a room with as many doors as possible (4, else 3, else 2).
place_avatar :: proc(g: ^Game) {
	for wanted := 4; wanted >= 2; wanted -= 1 {
		candidates := make([dynamic]int, context.temp_allocator)
		for room in 0 ..< ROOM_COUNT {
			if door_count(g, room) == wanted {
				append(&candidates, room)
			}
		}
		if len(candidates) == 0 {
			continue
		}
		room := candidates[rand.int_max(len(candidates))]
		tiles := free_floor_tiles(g, room)
		g.at = tiles[rand.int_max(len(tiles))]
		return
	}
	g.at = Loc{0, ROOM_COLS / 2, ROOM_ROWS / 2}
}

generate_world :: proc(g: ^Game) {
	g.feature_count = 0
	g.item_count = 0
	generate_maze(g)
	create_doors(g)
	populate_keys(g)
	populate(g, .Food, FOOD_COUNT)
	populate(g, .Tax_Form, TAX_FORM_COUNT)
	populate(g, .Pen, PEN_COUNT)
	populate(g, .Ink_Well, INK_WELL_COUNT)
	place_avatar(g)
	g.stats = {.Satiety = 100, .Health = 100, .Stomach = 0, .Bowel = 0, .Sanity = 100}
	free_all(context.temp_allocator)
}

// ---- looking ----------------------------------------------------------------------------------------------

// Appends to the message log without clearing it first.
look :: proc(g: ^Game) {
	if is_dead(g) {
		add_message(g, "%s is dead.", g.name)
		return
	}
	if is_insane(g) {
		add_message(g, "%s is insane.", g.name)
		return
	}
	add_message(g, "%s is on floor.", g.name)
	if has_items(g, .Ground) {
		add_message(g, "There is stuff on the ground.")
	}
	fs := features_at(g, g.at)
	if len(fs) > 0 {
		add_message(g, "Features:")
		for fi in fs {
			add_message(g, "- %s", feature_name(g.features[fi].kind))
		}
	}
}

show_status :: proc(g: ^Game) {
	add_message(g, "Status:")
	add_message(g, "Stomach: %d/%d", g.stats[.Stomach], stat_max[.Stomach])
	add_message(g, "Bowel: %d/%d", g.stats[.Bowel], stat_max[.Bowel])
	add_message(g, "Satiety: %d/%d", g.stats[.Satiety], stat_max[.Satiety])
	add_message(g, "Health: %d/%d", g.stats[.Health], stat_max[.Health])
	add_message(g, "Sanity: %d/%d", g.stats[.Sanity], stat_max[.Sanity])
}

// ---- avatar verbs ----------------------------------------------------------------------------------------------

can_perform :: proc(g: ^Game, v: Avatar_Verb) -> bool {
	switch v {
	case .North, .East, .South, .West:
		return can_act(g)
	case .Look, .Status:
		return true
	case .Poop:
		return can_act(g) && g.stats[.Bowel] >= stat_max[.Bowel] / 2
	}
	return false
}

verb_direction :: proc(v: Avatar_Verb) -> Direction {
	#partial switch v {
	case .East:  return .East
	case .South: return .South
	case .West:  return .West
	}
	return .North
}

// `move_roll` is uniform in [0,1) and decides the sanity bonus on a successful step.
perform :: proc(g: ^Game, v: Avatar_Verb, move_roll: f64 = 0) {
	if !can_perform(g, v) {
		return
	}
	clear_messages(g)
	switch v {
	case .North, .East, .South, .West:
		move(g, verb_direction(v), move_roll)
	case .Look:
		look(g)
	case .Status:
		show_status(g)
	case .Poop:
		poop(g)
	}
}

move :: proc(g: ^Game, d: Direction, move_roll: f64) {
	dx, dy := direction_delta(d)
	next := Loc{g.at.room, g.at.col + dx, g.at.row + dy}
	if !is_floor(g, next) {
		add_message(g, "%s cannot move %s.", g.name, direction_name(d))
		return
	}
	if g.stats[.Sanity] != stat_max[.Sanity] && move_roll < 0.5 {
		change_stat(g, .Sanity, 1)
	}
	add_message(g, "%s moves %s.", g.name, direction_name(d))
	do_biology(g, 1)
	g.at = next
	look(g)
}

poop :: proc(g: ^Game) {
	pile := -1
	for fi in features_at(g, g.at) {
		if g.features[fi].kind == .Poo_Pile {
			pile = fi
			break
		}
	}
	if pile < 0 {
		pile = add_feature(g, .Poo_Pile, g.at)
	}
	amount := g.stats[.Bowel] / 2
	change_stat(g, .Bowel, -amount)
	if pile >= 0 {
		g.features[pile].poo += amount
	}
}

// ---- features ------------------------------------------------------------------------------------------------------

has_item_kind :: proc(g: ^Game, kind: Item_Kind) -> bool {
	for i in 0 ..< g.item_count {
		it := &g.items[i]
		if it.alive && it.place == .Inventory && it.kind == kind {
			return true
		}
	}
	return false
}

// The first pen in the inventory that has ink / has room for ink, or -1.
first_pen_with_ink :: proc(g: ^Game) -> int {
	for i in 0 ..< g.item_count {
		it := &g.items[i]
		if it.alive && it.place == .Inventory && it.kind == .Pen && it.ink > 0 {
			return i
		}
	}
	return -1
}

first_pen_not_full :: proc(g: ^Game) -> int {
	for i in 0 ..< g.item_count {
		it := &g.items[i]
		if it.alive && it.place == .Inventory && it.kind == .Pen && it.ink < PEN_INK_MAX {
			return i
		}
	}
	return -1
}

describe_feature :: proc(g: ^Game, fi: int) {
	f := &g.features[fi]
	add_message(g, "This is %s %s.", f.kind == .Ink_Well ? "an" : "a", feature_name(f.kind))
	switch f.kind {
	case .Door:
		if f.locked {
			add_message(g, "%s is locked.", feature_name(f.kind))
		}
	case .Tax_Form:
		add_message(g, "Completeness: %d%%", f.completeness * 100 / TAX_FORM_MAX)
	case .Poo_Pile:
		add_message(g, "%s has %d poo.", feature_name(f.kind), f.poo)
	case .Ink_Well:
	}
}

can_feature_verb :: proc(g: ^Game, fi: int, v: Feature_Verb) -> bool {
	if !can_act(g) {
		return false
	}
	f := &g.features[fi]
	switch v {
	case .Enter:
		return !f.locked
	case .Unlock:
		return f.locked && has_item_kind(g, .Key)
	case .Fill_Out:
		return f.completeness < TAX_FORM_MAX && first_pen_with_ink(g) >= 0
	case .Sign:
		return f.completeness >= TAX_FORM_MAX && first_pen_with_ink(g) >= 0
	case .Refill_Pen:
		return first_pen_not_full(g) >= 0
	}
	return false
}

perform_feature_verb :: proc(g: ^Game, fi: int, v: Feature_Verb) {
	if !feature_exists_here(g, fi) || !can_feature_verb(g, fi, v) {
		return
	}
	clear_messages(g)
	f := &g.features[fi]
	switch v {
	case .Enter:
		add_message(g, "%s enters %s.", g.name, feature_name(f.kind))
		g.at = f.dest
		look(g)
	case .Unlock:
		add_message(g, "%s unlocks %s.", g.name, feature_name(f.kind))
		f.locked = false
		for i in 0 ..< g.item_count {
			it := &g.items[i]
			if it.alive && it.place == .Inventory && it.kind == .Key {
				it.alive = false
				break
			}
		}
	case .Fill_Out:
		pen := &g.items[first_pen_with_ink(g)]
		report_change(g, item_name(.Pen), "ink", &pen.ink, PEN_INK_MAX, -1)
		report_change(g, feature_name(f.kind), "completeness", &f.completeness, TAX_FORM_MAX, 1)
		change_stat(g, .Sanity, -1)
	case .Sign:
		pen := &g.items[first_pen_with_ink(g)]
		add_message(g, "%s signs %s.", g.name, feature_name(f.kind))
		report_change(g, item_name(.Pen), "ink", &pen.ink, PEN_INK_MAX, -1)
		change_stat(g, .Sanity, 10)
		f.alive = false
	case .Refill_Pen:
		pen := &g.items[first_pen_not_full(g)]
		report_change(g, item_name(.Pen), "ink", &pen.ink, PEN_INK_MAX, PEN_INK_MAX - pen.ink)
	}
}

// ---- items ---------------------------------------------------------------------------------------------------------------

describe_item :: proc(g: ^Game, ii: int) {
	it := &g.items[ii]
	add_message(g, "It is a %s.", item_name(it.kind))
	if it.kind == .Pen {
		add_message(g, "Ink: %d/%d", it.ink, PEN_INK_MAX)
	}
}

perform_item_verb :: proc(g: ^Game, ii: int, v: Item_Verb) {
	clear_messages(g)
	it := &g.items[ii]
	switch v {
	case .Eat:
		change_stat(g, .Stomach, it.stomach)
		it.alive = false
	}
}

take_item :: proc(g: ^Game, ii: int) {
	clear_messages(g)
	add_message(g, "%s takes %s.", g.name, item_name(g.items[ii].kind))
	g.items[ii].place = .Inventory
}

drop_item :: proc(g: ^Game, ii: int) {
	clear_messages(g)
	add_message(g, "%s drops %s.", g.name, item_name(g.items[ii].kind))
	g.items[ii].place = .Ground
	g.items[ii].at = g.at
}

// Moves up to `count` items of a kind between the ground and the inventory.
move_stack :: proc(g: ^Game, kind: Item_Kind, from: Place, count: int) {
	stack := stack_of(g, from, kind)
	n := min(count, stack.count)
	clear_messages(g)
	add_message(g, "%s %s %d %s.", g.name, from == .Ground ? "takes" : "drops", n, item_name(kind))
	moved := 0
	for i in 0 ..< g.item_count {
		if moved >= n {
			break
		}
		if in_container(&g.items[i], from, g.at) && g.items[i].kind == kind {
			if from == .Ground {
				g.items[i].place = .Inventory
			} else {
				g.items[i].place = .Ground
				g.items[i].at = g.at
			}
			moved += 1
		}
	}
}

// ---- ads -------------------------------------------------------------------------------------------------------------------------

ad_start :: proc(g: ^Game, now_ms: i64) {
	g.ad_active = true
	g.ad_finish_ms = now_ms + AD_BREAK_MS
}

// `sponsor_roll` is uniform in [0,1) and picks one of three sponsors.
ad_show :: proc(g: ^Game, now_ms: i64, sponsor_roll: f64) {
	clear_messages(g)
	if g.ad_finish_ms > now_ms {
		secs := (g.ad_finish_ms - now_ms) / 1000
		add_message(g, "Time left in ad break: %02d:%02d", secs / 60, secs % 60)
		add_message(g, "(This is a turn based game. As such, this counter will not automatically change. You have to click the OK button to refresh.)")
		switch min(int(sponsor_roll * 3), 2) {
		case 0: add_link(g, "For all yer umlauting needs! umlaut.fyi", "https://umlaut.fyi/")
		case 1: add_link(g, "Everybody loves Pen 15!", "https://pen15.site/")
		case:   add_link(g, "Circling back, don't, which is frankly cross-functional, forget (event-driven) to Jargonize before the next raise!", "https://jargonize.app/")
		}
	} else {
		add_message(g, "Ad break is complete! You may return to yer metaphor!")
		g.ad_active = false
	}
}
