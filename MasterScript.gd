extends Node3D

@export var welcome_screen:PackedScene
@export var expositions:Array[PackedScene]
@export_file var textdb_location 

var rot_speed = 0.75
var interpolator = 0
var target:float = 0
var sample_base_pos = true
var base_pos = Vector2(0,0)
var out_of_bounds = 5.75
var rotation_index = 0
var current_room = 0
var scene_order:Array[PackedScene]

var right_button_down:bool = false
var left_button_down:bool = false
var can_open_dialog:bool = false

var opened_file:FileAccess = null
var text_dict:Dictionary

@onready var regex_searcher = RegEx.new()

@onready var last_probed_detector = $Building/Detectors/f_right/f_right_probe
@onready var camera_pivot = $CameraPivot

@onready var current_rotation = camera_pivot.rotation.y
@onready var viewport_size = get_viewport().size

@onready var character = $Character
@onready var character_probe = $Character/Probe
@onready var detectors = [$Building/Detectors/f_right/f_right_probe,$Building/Detectors/b_right/b_right_probe,$Building/Detectors/b_left/b_left_probe, $Building/Detectors/f_left/f_left_probe]

@onready var left_button = $Control/HBoxContainer/CenterContainer/MarginContainer2/AspectRatioContainer3/Left_Button
@onready var right_button = $Control/HBoxContainer/CenterContainer2/MarginContainer/AspectRatioContainer2/Right_Button
@onready var dialog_container = $Control/HBoxContainer/MainTextContainer/MainTextRect
@onready var exit_dialog = $Control/HBoxContainer/MainTextContainer/MainTextRect/VBoxContainer/HBoxContainer/MarginContainer2/AspectRatioContainer/DialogExitButton

@onready var main_text = $Control/HBoxContainer/MainTextContainer/MainTextRect/VBoxContainer/marg/MainText
@onready var main_title = $Control/HBoxContainer/MainTextContainer/MainTextRect/VBoxContainer/HBoxContainer/MarginContainer/MainTitle
@onready var open_prompt = find_child("open_prompt")
# Called when the node enters the scene tree for the first time.
func _ready():
	
	initialize_scene_order()
	initial_instantiation()
	connect_all_signals()
	
	#load text into game
	text_dict = load_dictionary_from_csv(textdb_location)
	main_title.text = text_dict["default_title"]
	main_text.text = text_dict["default_text"]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	current_rotation = camera_pivot.rotation.y
	# match current rot to target rot
	match_scene_to_target(delta)
	character_out_of_bounds()
	gui_controls()

func _physics_process(_delta):
	pass

func _character_probed(probed_area) -> void:
	var is_detector = detectors.find(probed_area) >= 0
	var node_parent = probed_area.get_parent()
	var parent_name =  get_node_name(node_parent).to_lower() if (node_parent != null) else "null"
	
	if is_detector:
		set_target_on_probe(probed_area)
		
	elif parent_name == "info_boxes":
		var node_id = get_node_name(probed_area).to_lower()
		var node_title = node_id + "_title"
		main_title.text = ("[center]" + text_dict[node_title]) if node_title in text_dict else ("[center]" + text_dict["default_title"])
		main_text.text = (text_dict[node_id]) if node_title in text_dict else (text_dict["default_text"])
		can_open_dialog = true

func match_scene_to_target(delta) -> void:
	#Matches all parameters to target and executes rotation and such
	if !compare_floats(rad_to_deg(current_rotation),(target), 0.0001):
		interpolator = clamp(interpolator +(delta / rot_speed), 0, 1)
		camera_pivot.rotation.y = lerp(camera_pivot.rotation.y, deg_to_rad(target), interpolator*interpolator)
		
		character.rotation.y = camera_pivot.rotation.y
		character.global_position = character.global_position.lerp(last_probed_detector.global_position, interpolator)
		character.motion_vector = Vector2(cos(current_rotation), sin(current_rotation))
		character.ignore_input = true
		
	elif interpolator != 0:
		camera_pivot.rotation.y = deg_to_rad(target)
		character.rotation.y = camera_pivot.rotation.y
		character.global_position = last_probed_detector.global_position
		character.motion_vector = Vector2(cos(current_rotation), sin(current_rotation))
		character.ignore_input = false
		interpolator = 0
	else:
		character.ignore_input = false

func character_out_of_bounds() -> void:
	var _char_z = abs(character.position.z) > out_of_bounds
	var _char_x = abs(character.position.x) > out_of_bounds
	if (_char_x || _char_z) && interpolator == 0:
		_character_probed(last_probed_detector)
	pass

func load_in_scene(spawn_on:Node, scene_to_spawn:PackedScene) -> void:
	if spawn_on.get_child_count() > 0:
		var to_destroy = spawn_on.get_children()
		for x in to_destroy:
			x.queue_free()
	var scn = scene_to_spawn.instantiate()
	spawn_on.add_child(scn)

func initialize_scene_order() -> void:
		#shuffles expositions
	randomize()
	#initial instantation 
	scene_order.append_array(expositions)
	scene_order.shuffle()
	scene_order.push_front(welcome_screen)

func initial_instantiation() -> void: 
	for i in range(-1,3):
		var target_node = get_node("Building/SpawnPoints/%d" % overflow_int(rotation_index,i,4))
		load_in_scene(target_node,scene_order[overflow_int(current_room, i, scene_order.size())])
	pass

func set_target_on_probe(probed_area:Area3D) -> void:
	var detector_index = detectors.find(probed_area)
	var current_target_index:int = (int(target) / int(90.0))%4
	var negative_mod = -2*(signi(current_target_index) - 1*abs(signi(current_target_index)))
	var corrected_index = current_target_index + negative_mod
	
	var turn_direction = 1
	
	rotation_index = corrected_index
	
	if detector_index < corrected_index || ((detector_index == 3)&&(corrected_index == 0)):
		turn_direction = -1 
	elif detector_index == corrected_index:
		turn_direction = 1
	
	var load_at = get_node("Building/SpawnPoints/%d" % overflow_int(rotation_index, turn_direction*2,4))
	var to_load = scene_order[overflow_int(current_room, turn_direction * 2, scene_order.size())]
	load_in_scene(load_at, to_load)
	
	current_room = overflow_int(current_room, turn_direction, scene_order.size())
	target += 90*turn_direction
	
	last_probed_detector = probed_area

func gui_controls() -> void:
	#UI controls
	character.button_walk = int(left_button_down) - int(right_button_down)
	character.ignore_input = dialog_container.visible
	character.can_interact = can_open_dialog
	
	open_prompt.visible = can_open_dialog && !dialog_container.visible
	if open_prompt.visible:
		#dumb way to lerp it
		if sample_base_pos:
			base_pos = find_child("Camera3D").unproject_position(character.position)
		else:
			var desired_pos = find_child("Camera3D").unproject_position(character.position)
			var differential = (desired_pos - base_pos)/30.0
			base_pos += differential
			pass
		var prompt_pos = base_pos - find_child("open_prompt").get("size") * find_child("open_prompt").get("scale")/2.0
		#offets to be above player
		prompt_pos += Vector2(-10.0,-220.0)
		#breathiing
		prompt_pos += Vector2(sin(Time.get_ticks_msec()/1000.0)*5.0,cos(Time.get_ticks_msec()/1000.0)*15.0)
		open_prompt.set("position", prompt_pos)
		
		var prompt_vect = prompt_pos - find_child("Camera3D").unproject_position(character.position)
		prompt_vect = prompt_vect.normalized()
		var prompt_heading = (asin(Vector2(1,0).dot(prompt_vect)))
		
		var prompt_rot = sin(Time.get_ticks_msec()/1000.0)*deg_to_rad(15)
		open_prompt.set("rotation",prompt_rot + prompt_heading)
		sample_base_pos = false
	else:
		sample_base_pos = true

func connect_all_signals() -> void:
	#connects signals
	character_probe.area_entered.connect(_character_probed)
	character_probe.area_exited.connect(_character_probed_exit)
	character._interact_signal.connect(_open_dialog)
	open_prompt.button_down.connect(_open_dialog)
	
	right_button.button_down.connect(_right_button)
	right_button.button_up.connect(_right_button)
	
	left_button.button_down.connect(_left_button)
	left_button.button_up.connect(_left_button)
	
	exit_dialog.button_down.connect(_exit_dialog)

func load_dictionary_from_csv(file_path:String) -> Dictionary:
	var temp_dict:Dictionary
	var temp_file = FileAccess.open( file_path, FileAccess.READ )
	while !temp_file.eof_reached():
		var csv_line = temp_file.get_csv_line(";")
		if csv_line[0] != "ID" && csv_line.size() > 1:
			temp_dict[csv_line[0].to_lower()] = csv_line[1]
	temp_file = null
	return temp_dict
	pass
#helpers
func _right_button() -> void:
	right_button_down = !right_button_down
func _left_button() -> void:
	left_button_down = !left_button_down
func overflow_int(rot:int,dir:int,size:int) -> int:
	var dir_n = dir%size
	var rot_out = rot + dir_n
	if rot_out < -0.001:
		rot_out += size
	rot_out = rot_out % size
	return rot_out
func _exit_dialog() -> void:
	dialog_container.visible = false
func _open_dialog() -> void:
	dialog_container.visible = true
func get_node_name(node:Node) -> String:
	regex_searcher.compile("^()\\w+")
	return regex_searcher.search(str(node)).get_string()
func compare_floats(f1:float,f2:float,tolerance:float) -> bool:
	return abs(f1 - f2) <= tolerance
func _character_probed_exit(probed_area) -> void:
	var node_parent = probed_area.get_parent()
	var parent_name =  get_node_name(node_parent).to_lower() if (node_parent != null) else "null"
	if parent_name == "info_boxes":
		can_open_dialog = false
