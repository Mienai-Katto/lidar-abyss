extends Camera3D

@export var scan_interval: float = 8.5
@export var ray_count: int = 500
@export var ray_length: float = 100.0
@export var sweep_steps_horizontal: int = 100
@export var sweep_steps_vertical: int = 100
@export var point_size: float = 2.5
@export var fade_power: float = 0.15

var lidar_sfx = preload("res://sfx/lidar-base.mp3")
var lidar_full_sfx = preload("res://sfx/lidar-full.mp3")

var point_positions = []
var point_mesh_instance: MeshInstance3D
var point_material: ShaderMaterial

func _ready():
	# Initialize the MeshInstance3D
	point_mesh_instance = MeshInstance3D.new()

	# Add to the root node or a stationary node
	get_tree().get_root().add_child.call_deferred(point_mesh_instance)

	# Reset its transform
	point_mesh_instance.transform = Transform3D()

	# Create and assign the shader material
	point_material = ShaderMaterial.new()
	point_material.shader = load("res://shaders/lidar.gdshader")
	point_mesh_instance.material_override = point_material

	# Set initial point size
	point_material.set_shader_parameter("point_size", point_size)
	point_material.set_shader_parameter("max_fade_distance", ray_length)
	point_material.set_shader_parameter("fade_power", fade_power)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			perform_environment_scan()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			await perform_full_sweep()

func _process(delta):
	var points_updated = false
	for point in point_positions:
		point["time_left"] -= delta
		if point["time_left"] <= 0:
			points_updated = true

	if points_updated:
		point_positions = point_positions.filter(filter_by_time_left)
		update_point_mesh()
	
	# Pass the camera's position to the shader
	point_material.set_shader_parameter("player_position", global_position)

func filter_by_time_left(p):
	return p["time_left"] > 0

func perform_environment_scan():
	$"../AudioStreamPlayer".stream = lidar_sfx
	$"../AudioStreamPlayer".play()
	var camera_forward = -global_transform.basis.z
	

	for i in range(ray_count):
		# Create a cone of rays in front of the camera
		var ray_direction = camera_forward.rotated(Vector3.UP, randf_range(-PI/4, PI/4))
		ray_direction = ray_direction.rotated(Vector3.RIGHT, randf_range(-PI/4, PI/4))
		ray_direction = ray_direction.normalized()

		var ray_origin = global_position
		var ray_target = ray_origin + ray_direction * ray_length

		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
		query.exclude = [get_parent().get_rid()]
		var result = space_state.intersect_ray(query)

		if result:
			var collider = result.collider
			var is_red = is_node_in_group_or_parent(collider, "red")
			point_positions.append({
				"position": result.position,
				"is_red": is_red,
				"time_left": scan_interval
			})
	update_point_mesh()

func update_point_mesh():
	var vertices = PackedVector3Array()
	var colors = PackedColorArray()

	for point in point_positions:
		vertices.append(point["position"])
		var color = Color(1, 0, 0, 1) if point["is_red"] else Color(1, 1, 1, 1)
		colors.append(color)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors

	if arrays[Mesh.ARRAY_VERTEX].size() > 0:
		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)
		point_mesh_instance.mesh = mesh

func is_node_in_group_or_parent(node: Node, group_name: String) -> bool:
	var current_node = node
	while current_node != null:
		if current_node.is_in_group(group_name):
			return true
		current_node = current_node.get_parent()
	return false

func perform_full_sweep():
	$"../AudioStreamPlayer".stream = lidar_full_sfx
	$"../AudioStreamPlayer".play()
	var viewport_size = get_viewport().get_texture().get_size()
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.exclude = [get_parent().get_rid()]

	var x_step = viewport_size.x / (sweep_steps_horizontal - 1.0)
	var y_step = viewport_size.y / (sweep_steps_vertical - 1.0)
	var max_offset = 0.5 * min(x_step, y_step)

	var rows_per_frame = 1  # Adjust this value for speed and smoothness

	for i in range(0, sweep_steps_vertical, rows_per_frame):
		for k in range(rows_per_frame):
			var row = i + k
			if row >= sweep_steps_vertical:
				break
			var y = (row / (sweep_steps_vertical - 1.0)) * viewport_size.y
			for j in range(sweep_steps_horizontal):
				var x = (j / (sweep_steps_horizontal - 1.0)) * viewport_size.x

				var x_offset = randf_range(-max_offset, max_offset)
				var y_offset = randf_range(-max_offset, max_offset)

				var screen_pos = Vector2(x + x_offset, y + y_offset)
				var ray_origin = project_ray_origin(screen_pos)
				var ray_direction = project_ray_normal(screen_pos)

				query.from = ray_origin
				query.to = ray_origin + ray_direction * ray_length

				var result = space_state.intersect_ray(query)
				if result:
					var collider = result.collider
					var is_red = is_node_in_group_or_parent(collider, "red")
					point_positions.append({
						"position": result.position,
						"is_red": is_red,
						"time_left": scan_interval
					})
		update_point_mesh()
		await get_tree().process_frame
