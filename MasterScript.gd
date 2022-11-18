extends Node3D

var rot_speed = 4
var interpolator = 0
var target:float = 0


var out_of_bounds = 5.75
var rotation_index = 0

@onready var last_probed_detector = $Building/Detectors/f_right/f_right_probe
@onready var camera_pivot = $CameraPivot

@onready var current_rotation = camera_pivot.rotation.y

@onready var character = $Character
@onready var character_probe = $Character/Probe
@onready var detectors = [$Building/Detectors/f_right/f_right_probe,$Building/Detectors/b_right/b_right_probe,$Building/Detectors/b_left/b_left_probe, $Building/Detectors/f_left/f_left_probe]

# Called when the node enters the scene tree for the first time.
func _ready():
	
	character_probe.area_entered.connect(_character_probed)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	current_rotation = camera_pivot.rotation.y
	
	# match current rot to target rot
	match_scene_to_target(delta)
	character_out_of_bounds()
	
	pass

func _physics_process(_delta):
	pass

func _character_probed(probed_area):
	var detector_index = detectors.find(probed_area)
	var current_target_index:int = (int(target) / int(90.0))%4
	var negative_mod = -2*(signi(current_target_index) - 1*abs(signi(current_target_index)))
	var corrected_index = current_target_index + negative_mod
	
	rotation_index = corrected_index
	
	if detector_index < corrected_index || ((detector_index == 3)&&(corrected_index == 0)):
		target -= 90
	elif detector_index == corrected_index:
		target += 90
	
	print(detector_index)
	print(corrected_index)
	print(negative_mod)
	print(current_target_index)
	print("-----------------------")
	
	last_probed_detector = probed_area
	pass

func match_scene_to_target(delta):
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
		print("booo")
		load_in_scene(0,0)

func compare_floats(f1:float,f2:float,tolerance:float) -> bool:
	return abs(f1 - f2) <= tolerance

func character_out_of_bounds() -> void:
	var _char_z = abs(character.position.z) > out_of_bounds
	var _char_x = abs(character.position.x) > out_of_bounds
	if (_char_x || _char_z) && interpolator == 0:
		_character_probed(last_probed_detector)
	pass

func load_in_scene(spawn_on, index_to_spawn):
	pass
