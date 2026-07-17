extends Node2D

const TILE_W := 96.0
const TILE_H := 48.0
const MOVE_SPEED := 190.0
const MAP_TEXTURE_PATH := "res://art/campaign_map.png"
const FIRST_LEVEL_TEXTURE_PATH := "res://art/level_01_house.png"

var chapters: Array[Dictionary] = [
	{
		"title": "Chapter 1 - The Last Tap",
		"difficulty": "Normal",
		"map_note": "The district pump runs dry.",
		"start_story": "Mira, Sami, and old Yara reach a broken apartment block before dawn. The pipes cough once, then go silent. No one asks for comfort. They ask where the water is.",
		"end_story": "They fill one cracked kettle before the shelling starts again. It is not enough for tomorrow, but it is enough for the next street.",
		"time": 95,
		"required": {"water": 2},
		"sites": [
			{"name": "Kitchen pipe", "item": "water", "amount": 1, "pos": Vector2(-250, 185), "text": "Cold drops gather beneath the kitchen arch, slow enough to count."},
			{"name": "Rooftop barrel", "item": "water", "amount": 1, "pos": Vector2(-190, -245), "text": "Rainwater waits in a rooftop barrel above the sleeping rooms."},
			{"name": "Empty cupboard", "item": "hope", "amount": -1, "pos": Vector2(375, -130), "text": "Only jars and folded cloth. Yara recognizes the silence of a used-up home."}
		]
	},
	{
		"title": "Chapter 2 - Bread Line",
		"difficulty": "Normal",
		"map_note": "A bakery becomes a checkpoint.",
		"start_story": "By noon the queue is longer than the road. People trade watches, wedding rings, and stories about children who stopped crying because they were too tired.",
		"end_story": "Sami carries half a loaf under his coat. Behind him, the line breaks into shouting, then running. He does not look back.",
		"time": 85,
		"required": {"food": 2},
		"sites": [
			{"name": "Burned stall", "item": "food", "amount": 1, "pos": Vector2(-180, 45), "text": "A handful of lentils spills from a torn sack."},
			{"name": "Bakery crate", "item": "food", "amount": 1, "pos": Vector2(105, -80), "text": "Hard bread, almost stone. Everyone smiles anyway."},
			{"name": "Pantry shelf", "item": "food", "amount": 1, "pos": Vector2(-20, 125), "text": "A jar of beans waits behind broken glass."},
			{"name": "Crying neighbor", "item": "hope", "amount": 1, "pos": Vector2(185, 95), "text": "You share a crust. It costs food, but keeps a person standing.", "cost": {"food": 1}}
		]
	},
	{
		"title": "Chapter 3 - The Hospital Stairs",
		"difficulty": "Hard",
		"map_note": "Medicine is upstairs. The stairs are gone.",
		"start_story": "Mira's brother burns with fever. The clinic still has medicine, someone says, if you can cross the exposed stairwell and ignore the names written on the walls.",
		"end_story": "The fever breaks near sunrise. Nobody cheers. They are too busy listening for the next blast.",
		"time": 70,
		"required": {"medicine": 2},
		"sites": [
			{"name": "Nurse desk", "item": "medicine", "amount": 1, "pos": Vector2(-135, -85), "text": "Two pills in paper. The handwriting says: for children first."},
			{"name": "Cold cabinet", "item": "medicine", "amount": 1, "pos": Vector2(125, -45), "text": "Most vials are spoiled. One box survived."},
			{"name": "Open stairwell", "item": "hope", "amount": -2, "pos": Vector2(15, 125), "text": "Glass rains from above. Every step sounds too loud."}
		]
	},
	{
		"title": "Chapter 4 - Letters Under Bricks",
		"difficulty": "Normal",
		"map_note": "The street remembers its missing.",
		"start_story": "The survivors do not need supplies tonight. They need proof that someone lived here, loved here, waited here.",
		"end_story": "Yara folds the letters into her scarf. Names are light, until you carry them.",
		"time": 90,
		"required": {"letters": 3},
		"sites": [
			{"name": "Collapsed bedroom", "item": "letters", "amount": 1, "pos": Vector2(-190, -35), "text": "A child's drawing of a blue house, though the house was never blue."},
			{"name": "Bus shelter", "item": "letters", "amount": 1, "pos": Vector2(30, -125), "text": "A note: wait for me near the old cinema."},
			{"name": "Cracked doorway", "item": "letters", "amount": 1, "pos": Vector2(175, 70), "text": "A photograph survives because it was turned face-down."}
		]
	},
	{
		"title": "Chapter 5 - The Well Road",
		"difficulty": "Very Hard",
		"map_note": "Water is beyond the open road.",
		"start_story": "The well is five streets away. Between here and there is a road so open it feels like a sentence. The cans are empty. Their throats are not.",
		"end_story": "They return with water and one fewer song. The road has taken the easy part of them.",
		"time": 55,
		"required": {"water": 3, "food": 1},
		"sites": [
			{"name": "Well bucket", "item": "water", "amount": 2, "pos": Vector2(-160, -115), "text": "The rope cuts your hands. The bucket rises full."},
			{"name": "Drain channel", "item": "water", "amount": 1, "pos": Vector2(45, 130), "text": "Muddy water. Boil it, pray, drink."},
			{"name": "Dropped ration", "item": "food", "amount": 1, "pos": Vector2(195, -10), "text": "A wrapped piece of cheese, warm from the dust."},
			{"name": "Open road", "item": "hope", "amount": -3, "pos": Vector2(-15, 5), "text": "No cover. No mercy. Just the terrible distance."}
		]
	}
]

var highest_unlocked := 0
var completed: Dictionary = {}
var current_chapter := 0
var mode := "map"
var story_active := false
var chapter_map_points: Array[Vector2] = [
	Vector2(78, 550),
	Vector2(279, 517),
	Vector2(561, 467),
	Vector2(898, 497),
	Vector2(1138, 581)
]

var active_root: Node
var map_root: Control
var level_root: Node2D
var hud_layer: CanvasLayer
var toast_label: Label
var player_body: Polygon2D
var player_shadow: Polygon2D
var player_pos := Vector2.ZERO
var level_sites: Array[Dictionary] = []
var level_inventory: Dictionary = {}
var level_hope := 3
var level_time := 90.0
var level_move_bounds := Rect2(Vector2(-310, -195), Vector2(620, 390))
var interaction_hint: Label


func _ready() -> void:
	get_viewport().size_changed.connect(_sync_map_root_size)
	_show_map()


func _process(delta: float) -> void:
	if mode != "level" or story_active:
		return

	level_time -= delta
	if level_time <= 0.0:
		_show_failure("Dawn arrives before the chapter can close. In this prototype, the level resets instead of punishing later chapters.")
		return

	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if direction.length() > 0.0:
		player_pos += direction.normalized() * MOVE_SPEED * delta
		player_pos.x = clampf(player_pos.x, level_move_bounds.position.x, level_move_bounds.position.x + level_move_bounds.size.x)
		player_pos.y = clampf(player_pos.y, level_move_bounds.position.y, level_move_bounds.position.y + level_move_bounds.size.y)
		_update_player()

	if Input.is_action_just_pressed("interact"):
		_try_interact()

	_update_hud()
	_update_hint()


func _clear_active() -> void:
	if hud_layer != null:
		hud_layer.queue_free()
	if active_root != null:
		active_root.queue_free()
	active_root = null
	map_root = null
	level_root = null
	hud_layer = null
	toast_label = null
	interaction_hint = null


func _show_map() -> void:
	mode = "map"
	story_active = false
	_clear_active()

	map_root = Control.new()
	_sync_control_to_viewport(map_root)
	active_root = map_root
	add_child(map_root)

	var map_texture := _load_map_texture()
	if map_texture != null:
		var map_image := TextureRect.new()
		map_image.texture = map_texture
		map_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		map_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		map_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		map_image.modulate = Color(0.95, 0.95, 0.92, 1.0)
		map_root.add_child(map_image)
	else:
		var bg := ColorRect.new()
		bg.color = Color("#141516")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		map_root.add_child(bg)

	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.035, 0.035, 0.12)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_root.add_child(shade)

	var title := Label.new()
	title.text = "Ashes Between Streets"
	title.position = Vector2(34, 24)
	title.add_theme_font_size_override("font_size", 36)
	map_root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "The first night starts in a bottom-left house. Each marker is a story chapter; supplies reset after every level."
	subtitle.position = Vector2(38, 76)
	subtitle.size = Vector2(720, 48)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 17)
	map_root.add_child(subtitle)

	var path := Line2D.new()
	path.width = 5
	path.default_color = Color(0.98, 0.86, 0.44, 0.82)
	path.z_index = 1
	map_root.add_child(path)

	path.points = PackedVector2Array(chapter_map_points)

	for i in chapters.size():
		_add_map_chapter(i, chapter_map_points[i])

	var footer := Label.new()
	footer.text = "Enter a chapter from the map. Complete the story objective to unlock the next chapter."
	footer.position = Vector2(38, 666)
	footer.size = Vector2(860, 28)
	footer.add_theme_font_size_override("font_size", 16)
	map_root.add_child(footer)


func _sync_control_to_viewport(control: Control) -> void:
	control.position = Vector2.ZERO
	control.size = get_viewport_rect().size


func _sync_map_root_size() -> void:
	if map_root != null:
		_sync_control_to_viewport(map_root)


func _load_map_texture() -> Texture2D:
	return _load_texture(MAP_TEXTURE_PATH)


func _load_texture(path: String) -> Texture2D:
	var imported_texture := ResourceLoader.load(path, "Texture2D") as Texture2D
	if imported_texture != null:
		return imported_texture

	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_warning("Could not load image: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _add_map_chapter(index: int, pos: Vector2) -> void:
	var chapter: Dictionary = chapters[index]
	var unlocked := index <= highest_unlocked
	var done := completed.has(index)

	var marker := Button.new()
	marker.position = pos - Vector2(24, 24)
	marker.size = Vector2(48, 48)
	marker.disabled = not unlocked
	marker.text = "%d" % [index + 1]
	marker.tooltip_text = chapter["title"]
	marker.add_theme_font_size_override("font_size", 18)
	map_root.add_child(marker)

	if unlocked:
		marker.pressed.connect(func() -> void:
			_start_chapter(index)
		)

	var label := Label.new()
	var label_offset := Vector2(-104, 48)
	if pos.y > 560.0:
		label_offset = Vector2(-104, -118)
	var label_pos := pos + label_offset
	label_pos.x = clampf(label_pos.x, 18.0, 1054.0)
	label_pos.y = clampf(label_pos.y, 128.0, 622.0)
	label.position = label_pos
	label.size = Vector2(208, 84)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "%s%s\n%s" % [chapter["title"], " (done)" if done else "", chapter["map_note"]]
	label.add_theme_font_size_override("font_size", 14)
	map_root.add_child(label)


func _start_chapter(index: int) -> void:
	current_chapter = index
	mode = "level"
	_clear_active()

	var chapter: Dictionary = chapters[current_chapter]
	level_time = float(chapter["time"])
	level_hope = 3
	level_inventory = {"water": 0, "food": 0, "medicine": 0, "letters": 0}
	level_sites = []
	for site in chapter["sites"]:
		var copy: Dictionary = site.duplicate(true)
		copy["taken"] = false
		level_sites.append(copy)

	level_root = Node2D.new()
	level_root.position = get_viewport_rect().size * 0.5
	active_root = level_root
	add_child(level_root)

	_build_level_world()
	_build_hud()

	_show_story_card(chapter["title"], chapter["start_story"], "Begin", func() -> void:
		story_active = false
	)


func _build_level_world() -> void:
	if current_chapter == 0:
		_build_first_level_house()
		return

	level_move_bounds = Rect2(Vector2(-310, -195), Vector2(620, 390))

	var bg := ColorRect.new()
	bg.color = Color("#101112")
	bg.position = Vector2(-2000, -2000)
	bg.size = Vector2(4000, 4000)
	bg.z_index = -200
	level_root.add_child(bg)

	for gx in range(-4, 5):
		for gy in range(-3, 4):
			var tile := Polygon2D.new()
			var p := _iso_to_screen(Vector2(gx, gy))
			tile.polygon = PackedVector2Array([
				p + Vector2(0, -TILE_H * 0.5),
				p + Vector2(TILE_W * 0.5, 0),
				p + Vector2(0, TILE_H * 0.5),
				p + Vector2(-TILE_W * 0.5, 0)
			])
			var shade := 0.17 + float((gx + gy + 8) % 3) * 0.025
			tile.color = Color(shade, shade * 0.96, shade * 0.86)
			tile.z_index = int(p.y) - 100
			level_root.add_child(tile)

	_add_ruin(Vector2(-250, -130), Vector2(150, 78), Color("#3b3833"))
	_add_ruin(Vector2(95, -165), Vector2(190, 88), Color("#302f31"))
	_add_ruin(Vector2(-70, 115), Vector2(230, 76), Color("#3a332f"))

	for i in level_sites.size():
		_add_site_marker(i)

	player_shadow = Polygon2D.new()
	player_shadow.polygon = PackedVector2Array([Vector2(0, -8), Vector2(20, 0), Vector2(0, 8), Vector2(-20, 0)])
	player_shadow.color = Color(0, 0, 0, 0.35)
	level_root.add_child(player_shadow)

	player_body = Polygon2D.new()
	player_body.polygon = PackedVector2Array([Vector2(0, -34), Vector2(17, -5), Vector2(10, 26), Vector2(-11, 26), Vector2(-18, -5)])
	player_body.color = Color("#b8b0a0")
	level_root.add_child(player_body)

	player_pos = Vector2(0, 20)
	_update_player()


func _build_first_level_house() -> void:
	level_move_bounds = Rect2(Vector2(-535, -260), Vector2(1070, 520))

	var bg := ColorRect.new()
	bg.color = Color("#0d1112")
	bg.position = Vector2(-2000, -2000)
	bg.size = Vector2(4000, 4000)
	bg.z_index = -300
	level_root.add_child(bg)

	var texture := _load_texture(FIRST_LEVEL_TEXTURE_PATH)
	if texture != null:
		var house := Sprite2D.new()
		house.texture = texture
		house.centered = true
		var viewport_size := get_viewport_rect().size
		var scale_factor := maxf(viewport_size.x / float(texture.get_width()), viewport_size.y / float(texture.get_height()))
		house.scale = Vector2(scale_factor, scale_factor)
		house.position = Vector2.ZERO
		house.z_index = -200
		level_root.add_child(house)

	var dusk := ColorRect.new()
	dusk.color = Color(0.04, 0.045, 0.045, 0.08)
	dusk.position = Vector2(-2000, -2000)
	dusk.size = Vector2(4000, 4000)
	dusk.z_index = -100
	level_root.add_child(dusk)

	for i in level_sites.size():
		_add_site_marker(i)

	player_shadow = Polygon2D.new()
	player_shadow.polygon = PackedVector2Array([Vector2(0, -8), Vector2(20, 0), Vector2(0, 8), Vector2(-20, 0)])
	player_shadow.color = Color(0, 0, 0, 0.35)
	level_root.add_child(player_shadow)

	player_body = Polygon2D.new()
	player_body.polygon = PackedVector2Array([Vector2(0, -34), Vector2(17, -5), Vector2(10, 26), Vector2(-11, 26), Vector2(-18, -5)])
	player_body.color = Color("#b8b0a0")
	level_root.add_child(player_body)

	player_pos = Vector2(-395, 150)
	_update_player()


func _iso_to_screen(grid: Vector2) -> Vector2:
	return Vector2((grid.x - grid.y) * TILE_W * 0.5, (grid.x + grid.y) * TILE_H * 0.5)


func _add_ruin(pos: Vector2, size: Vector2, color: Color) -> void:
	var face := Polygon2D.new()
	face.position = pos
	face.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, 0),
		Vector2(size.x * 0.5, 0),
		Vector2(size.x * 0.5, -size.y),
		Vector2(-size.x * 0.5, -size.y * 0.65)
	])
	face.color = color
	face.z_index = int(pos.y) - 20
	level_root.add_child(face)

	var cap := Polygon2D.new()
	cap.position = pos + Vector2(0, -size.y)
	cap.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, size.y * 0.35),
		Vector2(size.x * 0.5, 0),
		Vector2(size.x * 0.36, -18),
		Vector2(-size.x * 0.62, size.y * 0.21)
	])
	cap.color = color.lightened(0.12)
	cap.z_index = face.z_index - 1
	level_root.add_child(cap)


func _add_site_marker(index: int) -> void:
	var site: Dictionary = level_sites[index]
	var pos: Vector2 = site["pos"]

	var base := Polygon2D.new()
	base.position = pos
	base.polygon = PackedVector2Array([Vector2(0, -17), Vector2(34, 0), Vector2(0, 17), Vector2(-34, 0)])
	base.color = Color("#8a6f3d")
	base.z_index = int(pos.y) + 2
	level_root.add_child(base)
	site["node"] = base

	var label := Label.new()
	label.text = site["name"]
	label.position = pos + Vector2(-70, 20)
	label.size = Vector2(140, 34)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.z_index = int(pos.y) + 3
	level_root.add_child(label)


func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)

	var top := ColorRect.new()
	top.color = Color(0.04, 0.045, 0.045, 0.88)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.size = Vector2(1280, 96)
	hud_layer.add_child(top)

	toast_label = Label.new()
	toast_label.position = Vector2(38, 108)
	toast_label.size = Vector2(480, 70)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_font_size_override("font_size", 16)
	hud_layer.add_child(toast_label)

	interaction_hint = Label.new()
	interaction_hint.position = Vector2(470, 624)
	interaction_hint.size = Vector2(360, 42)
	interaction_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_hint.add_theme_font_size_override("font_size", 18)
	hud_layer.add_child(interaction_hint)

	var back := Button.new()
	back.text = "Map"
	back.position = Vector2(1164, 24)
	back.size = Vector2(78, 42)
	back.pressed.connect(func() -> void:
		_show_map()
	)
	hud_layer.add_child(back)

	_update_hud()


func _update_hud() -> void:
	if hud_layer == null:
		return

	var old := hud_layer.get_node_or_null("HudText")
	if old != null:
		old.queue_free()

	var chapter: Dictionary = chapters[current_chapter]
	var objective_parts: Array[String] = []
	for key in chapter["required"].keys():
		objective_parts.append("%s %d/%d" % [String(key).capitalize(), int(level_inventory.get(key, 0)), int(chapter["required"][key])])

	var hud := Label.new()
	hud.name = "HudText"
	hud.position = Vector2(34, 18)
	hud.size = Vector2(1080, 64)
	hud.text = "%s | %s | Time %.0f | Hope %d\nObjective: %s" % [
		chapter["title"],
		chapter["difficulty"],
		maxf(level_time, 0.0),
		level_hope,
		", ".join(objective_parts)
	]
	hud.add_theme_font_size_override("font_size", 18)
	hud_layer.add_child(hud)


func _update_player() -> void:
	player_shadow.position = player_pos + Vector2(0, 27)
	player_shadow.z_index = int(player_pos.y) + 8
	player_body.position = player_pos
	player_body.z_index = int(player_pos.y) + 10


func _try_interact() -> void:
	var nearest_index := -1
	var nearest_distance := 99999.0
	for i in level_sites.size():
		var site: Dictionary = level_sites[i]
		if site["taken"]:
			continue
		var distance := player_pos.distance_to(site["pos"])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i

	if nearest_index == -1 or nearest_distance > 62.0:
		_toast("No reachable place to search.")
		return

	var site: Dictionary = level_sites[nearest_index]
	var cost: Dictionary = site.get("cost", {})
	for key in cost.keys():
		if int(level_inventory.get(key, 0)) < int(cost[key]):
			_toast("You need %d %s to make this choice." % [int(cost[key]), key])
			return

	for key in cost.keys():
		level_inventory[key] = int(level_inventory.get(key, 0)) - int(cost[key])

	var item := String(site["item"])
	var amount := int(site["amount"])
	if item == "hope":
		level_hope += amount
	else:
		level_inventory[item] = int(level_inventory.get(item, 0)) + amount

	site["taken"] = true
	var node: Polygon2D = site["node"]
	node.color = Color("#3e3d39")

	_toast(site["text"])
	if level_hope <= 0:
		_show_failure("The night breaks their courage. The chapter can be retried; nothing carries into the next story node.")
		return

	_check_chapter_complete()


func _check_chapter_complete() -> void:
	var required: Dictionary = chapters[current_chapter]["required"]
	for key in required.keys():
		if int(level_inventory.get(key, 0)) < int(required[key]):
			return

	completed[current_chapter] = true
	highest_unlocked = maxi(highest_unlocked, min(current_chapter + 1, chapters.size() - 1))

	var chapter: Dictionary = chapters[current_chapter]
	_show_story_card("Chapter Complete", chapter["end_story"], "Return to map", func() -> void:
		_show_map()
	)


func _update_hint() -> void:
	if interaction_hint == null:
		return

	var nearest_name := ""
	var nearest_distance := 99999.0
	for site in level_sites:
		if site["taken"]:
			continue
		var distance := player_pos.distance_to(site["pos"])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_name = site["name"]

	if nearest_distance <= 62.0:
		interaction_hint.text = "Press E: %s" % nearest_name
	else:
		interaction_hint.text = "WASD or arrows to move"


func _toast(text: String) -> void:
	if toast_label != null:
		toast_label.text = text


func _show_story_card(title: String, body: String, button_text: String, on_done: Callable) -> void:
	story_active = true

	var layer := CanvasLayer.new()
	layer.name = "StoryLayer"
	add_child(layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)

	var panel := Panel.new()
	panel.position = Vector2(305, 142)
	panel.size = Vector2(670, 420)
	layer.add_child(panel)

	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(32, 28)
	title_label.size = Vector2(606, 52)
	title_label.add_theme_font_size_override("font_size", 28)
	panel.add_child(title_label)

	var body_label := Label.new()
	body_label.text = body
	body_label.position = Vector2(34, 104)
	body_label.size = Vector2(600, 210)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 19)
	panel.add_child(body_label)

	var button := Button.new()
	button.text = button_text
	button.position = Vector2(444, 340)
	button.size = Vector2(180, 48)
	button.pressed.connect(func() -> void:
		layer.queue_free()
		on_done.call()
	)
	panel.add_child(button)


func _show_failure(message: String) -> void:
	if story_active:
		return
	_show_story_card("Chapter Failed", message, "Retry chapter", func() -> void:
		_start_chapter(current_chapter)
	)
