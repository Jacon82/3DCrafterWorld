extends Node3D

@export var chunk_size: int = 64
@export var mesh_resolution: int = 2
@export var height_scale: float = 12.0
@export var noise_frequency: float = 0.02

@onready var mesh_instance = MeshInstance3D.new()
@onready var static_body = StaticBody3D.new()
@onready var collision_shape = CollisionShape3D.new()

var noise = FastNoiseLite.new()

func _ready():
	add_child(mesh_instance)
	mesh_instance.add_child(static_body)
	static_body.add_child(collision_shape)
	
	_setup_noise()
	_generate_terrain()
	_scatter_resources()
	
	call_deferred("_spawn_player")

func _setup_noise():
	noise.seed = WorldStateManager.world_seed
	noise.frequency = noise_frequency
	noise.noise_type = FastNoiseLite.TYPE_PERLIN

func _generate_terrain():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(chunk_size + 1):
		for x in range(chunk_size + 1):
			var y = noise.get_noise_2d(x, z) * height_scale
			var uv = Vector2(float(x) / chunk_size, float(z) / chunk_size)
			st.set_uv(uv)
			st.add_vertex(Vector3(x, y, z))
			
	for z in range(chunk_size):
		for x in range(chunk_size):
			st.add_index(x + (z * (chunk_size + 1)))
			st.add_index((x + 1) + (z * (chunk_size + 1)))
			st.add_index(x + ((z + 1) * (chunk_size + 1)))
			
			st.add_index((x + 1) + (z * (chunk_size + 1)))
			st.add_index((x + 1) + ((z + 1) * (chunk_size + 1)))
			st.add_index(x + ((z + 1) * (chunk_size + 1)))

	st.generate_normals()
	mesh_instance.mesh = st.commit()
	collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()
	print("[WorldGenerator] Terrain and collision generated.")

func _spawn_player():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("[WorldGenerator] Player group check failed. Retrying in next frame.")
		return
		
	var margin = chunk_size * 0.15
	var rx = randf_range(margin, chunk_size - margin)
	var rz = randf_range(margin, chunk_size - margin)
	var ry = (noise.get_noise_2d(rx, rz) * height_scale) + 5.0
	
	player.global_position = Vector3(rx, ry, rz)
	print("[WorldGenerator] Player deferred spawn successful at: ", player.global_position)

func _scatter_resources():
	for i in range(50):
		var rx = randf_range(0, chunk_size)
		var rz = randf_range(0, chunk_size)
		var ry = noise.get_noise_2d(rx, rz) * height_scale
		var spawn_pos = Vector3(rx, ry, rz)
		
		if noise.get_noise_2d(rx + 100, rz + 100) > 0.2:
			_spawn_placeholder(spawn_pos, "Tree", Color.DARK_GREEN, Vector3(0.5, 2.0, 0.5))
		else:
			_spawn_placeholder(spawn_pos, "Rock", Color.DARK_GRAY, Vector3(0.8, 0.5, 0.8))

func _spawn_placeholder(pos: Vector3, type_name: String, color: Color, size: Vector3):
	var instance = StaticBody3D.new()
	instance.name = type_name + "_" + str(pos.x) + "_" + str(pos.z)
	instance.position = pos
	
	var mesh_node = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	
	mesh_node.mesh = box
	mesh_node.material_override = mat
	
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	
	instance.add_child(mesh_node)
	instance.add_child(col)
	add_child(instance)
