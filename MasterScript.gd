extends Node3D

var rot_speed = 4
var interpolator = 0
var target:float = 0

var last_probed_detector = 0

@onready var camera_pivot = $CameraPivot

@onready var current_rotation = camera_pivot.rotation.y

@onready var character = $Character
@onready var character_probe = $Character/Probe
@onready var detectors = [$Building/Detectors/f_right/f_right_probe,$Building/Detectors/b_right/b_right_probe,$Building/Detectors/b_left/b_left_probe, $Building/Detectors/b_left/b_left_probe]

# Called when the node enters the scene tree for the first time.
func _ready():
	
	character_probe.area_entered.connect(_character_probed)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	current_rotation = camera_pivot.rotation.y
	print(current_rotation)
	# match current rot to target rot
	if abs(current_rotation - deg_to_rad(target)) > 0.001:
		interpolator = clamp(interpolator +(delta / rot_speed), 0, 1)
		camera_pivot.rotation.y = lerp(camera_pivot.rotation.y, deg_to_rad(target), interpolator*interpolator)
		
		character.rotation.y = camera_pivot.rotation.y
		character.global_position = character.global_position.lerp(last_probed_detector.global_position, interpolator)
		character.motion_vector = Vector2(cos(current_rotation), sin(current_rotation))
		
		print("aaaaa")
		
	else:
		interpolator = 0
	
	pass

func _physics_process(delta):
	pass

func _character_probed(probed_area):
	if probed_area == detectors[0]:
		target = 90
	last_probed_detector = probed_area
	print(probed_area)
	pass
