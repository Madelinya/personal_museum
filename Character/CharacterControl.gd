extends Node3D

signal _interact_signal

enum STATES {WALKING = 2, IDLE = 1, INTERACTING = 0}

@export var rot_speed = 5

var walk_dir = 0
var look_dir:Vector2 = Vector2(0,1)
var ignore_input = false;
var walk_spd = 0.5
var rot_mult = 0
var rot_spd = 0.25

@onready var animation_tree = $AnimationTree
@onready var ignore_move: bool = false
@onready var state = STATES.IDLE
@onready var motion_vector:Vector2 = Vector2(1.0,0.0) 
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#check input
	var interact_state = Input.is_action_pressed("interact_button") && !ignore_input
	walk_dir = int(Input.is_action_pressed("walk_left")) - int(Input.is_action_pressed("walk_right"))
	var walk_state = bool(walk_dir) && !ignore_input
	
	set_states(interact_state, walk_state)
	#state behavour
	match state:
		STATES.INTERACTING:
			interact_state(delta)
		STATES.WALKING:
			walk_state(delta)
		STATES.IDLE:
			idle_state(delta)
	pass

func set_states(interact_state, walk_state):
	if state == STATES.INTERACTING && !animation_tree["parameters/interact_oneshot/active"]:
		state = STATES.IDLE
	
	if state == STATES.IDLE && interact_state:
		state = STATES.INTERACTING
	elif state == STATES.IDLE && walk_state:
		state = STATES.WALKING
	elif state == STATES.WALKING && !walk_state:
		state = STATES.IDLE

func walk_state(delta):
	animation_tree["parameters/walking/current"] = 1
	var rot_add = delta*walk_dir/rot_spd
	rot_mult = clamp(rot_add + rot_mult, -1, 1)
	$CharRoot.rotation.y = deg_to_rad(90)*rot_mult
	position.x += walk_spd*walk_dir*delta*motion_vector.x
	position.z += -walk_spd*walk_dir*delta*motion_vector.y

func interact_state (_delta):
	if !animation_tree["parameters/interact_oneshot/active"]:
		animation_tree["parameters/interact_oneshot/active"] = true
	pass

func idle_state(delta):
	var rot_add = delta/rot_spd
	rot_mult = sign(rot_mult)*clamp(abs(rot_mult) - rot_add, 0, 1)
	$CharRoot.rotation.y = deg_to_rad(90)*rot_mult
	
	animation_tree["parameters/walking/current"] = 0
	pass

func emit_interact():
	emit_signal("_interact_signal")
