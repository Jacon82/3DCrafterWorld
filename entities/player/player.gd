extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003
const ROTATION_SPEED = 12.0
const MAX_INTERACT_DISTANCE = 3.5

@export var max_camera_zoom: float = 10.0
@export var min_camera_zoom: float = 3.0
@export var zoom_step: float = 0.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var was_on_floor = false

var camera_yaw: float = 0.0
var camera_pitch: float = deg_to_rad(-25.0)

@onready var camera_pivot = $CameraPivot
@onready var spring_arm = $CameraPivot/SpringArm3D
@onready var visual_mesh = $MeshInstance3D
@onready var interact_raycast = $CameraPivot/SpringArm3D/Camera3D/InteractRaycast

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_pivot.rotation.x = camera_pitch
	spring_arm.spring_length = min_camera_zoom
	print("[Player] Valheim-style movement initialized. Mesh rotation decoupled.")

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_yaw -= event.relative.x * MOUSE_SENSITIVITY
		camera_pitch -= event.relative.y * MOUSE_SENSITIVITY
		camera_pitch = clamp(camera_pitch, deg_to_rad(-89.0), deg_to_rad(45.0))
		
		camera_pivot.rotation.x = camera_pitch
		camera_pivot.rotation.y = camera_yaw

	if event.is_action_pressed("camera_zoom_in"):
		spring_arm.spring_length = clamp(spring_arm.spring_length - zoom_step, min_camera_zoom, max_camera_zoom)

	if event.is_action_pressed("camera_zoom_out"):
		spring_arm.spring_length = clamp(spring_arm.spring_length + zoom_step, min_camera_zoom, max_camera_zoom)

	if event.is_action_pressed("camera_reset"):
		camera_yaw = 0.0
		camera_pitch = deg_to_rad(-25.0)
		camera_pivot.rotation.x = camera_pitch
		camera_pivot.rotation.y = camera_yaw
		spring_arm.spring_length = min_camera_zoom
		print("[Player] Camera reset.")

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("interact") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_try_interact()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	was_on_floor = is_on_floor()

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var look_direction = camera_pivot.global_transform.basis
	var direction = (look_direction * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y = 0 
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		var target_rotation = atan2(-direction.x, -direction.z)
		visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_rotation, delta * ROTATION_SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	var collision_occurred = move_and_slide()
	
	if collision_occurred and get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider == null:
				push_error("[Player] Collision detected but collider is null.")

func _try_interact():
	interact_raycast.force_raycast_update()
	
	if interact_raycast.is_colliding():
		var target = interact_raycast.get_collider()
		if target == null: return
		var distance_to_target = global_position.distance_to(target.global_position)
		if distance_to_target <= MAX_INTERACT_DISTANCE:
			print("[Player] Interaction SUCCESS with: ", target.name)
		else:
			print("[Player] Interaction FAILED. Distance: ", distance_to_target)
