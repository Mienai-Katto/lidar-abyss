extends Camera3D

@export var scan_interval: float = 8.5
@export var ray_count: int = 500
@export var ray_length_scan: float = 20.0
@export var ray_length_sweep: float = 30.0
@export var sweep_steps_horizontal: int = 100
@export var sweep_steps_vertical: int = 100
@export var point_size: float = 2.5
@export var fade_power: float = 0.15
@export var environment_scan_cooldown: float = 0.8
@export var full_sweep_scan_cooldown: float = 3.6

var timer: Timer

var point_mesh_instance: MultiMesh
var point_mesh: MultiMeshInstance3D
var point_material: ShaderMaterial

var mesh_tail: int = 0
var max_mesh_count: int = 40_000

var lidar_sfx = preload("res://sfx/lidar-base.mp3")
var lidar_full_sfx = preload("res://sfx/lidar-full.mp3")

var last_environment_scan_time: float = -1000.0
var last_full_sweep_scan_time: float = -1000.0


func _ready():
	point_mesh_instance = MultiMesh.new()
	point_mesh_instance.transform_format = MultiMesh.TRANSFORM_3D
	point_mesh_instance.use_colors = true
	point_mesh_instance.instance_count = max_mesh_count
	var mesh = PointMesh.new()
	point_mesh_instance.mesh = mesh

	point_mesh = MultiMeshInstance3D.new()
	get_tree().get_root().add_child.call_deferred(point_mesh)
	point_mesh.transform = Transform3D()

	point_material = ShaderMaterial.new()
	point_material.shader = load("res://shaders/lidar.gdshader")
	var point_material_test := StandardMaterial3D.new()
	point_material_test.albedo_color = Color(1, 1, 1)
	point_material_test.vertex_color_use_as_albedo = true
	point_material_test.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	point_mesh.material_override = point_material_test
	point_mesh.multimesh = point_mesh_instance

	point_material.set_shader_parameter("point_size", point_size)
	point_material.set_shader_parameter("max_fade_distance", ray_length_sweep)
	point_material.set_shader_parameter("fade_power", fade_power)

	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.01
	get_tree().get_root().add_child.call_deferred(timer)


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# perform_environment_scan()
			var ahead_of_camera = global_transform * Vector3(0, 0, -1)
			point_mesh_instance.set_instance_transform(0, Transform3D(Basis(), ahead_of_camera))
			point_mesh_instance.set_instance_color(0, Color(1.0, 1.0, 1.0))
			print("Trying to add point at ", Transform3D(Basis(), ahead_of_camera))
			pass
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			perform_full_sweep()


func _process(_delta):
	point_material.set_shader_parameter("player_position", global_position)


func is_node_in_group_or_parent(node: Node, group_name: String) -> bool:
	var current_node = node
	while current_node != null:
		if current_node.is_in_group(group_name):
			return true
		current_node = current_node.get_parent()
	return false


func perform_full_sweep():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time < last_full_sweep_scan_time + full_sweep_scan_cooldown:
		return

	last_full_sweep_scan_time = current_time
	$"../AudioStreamPlayer".stream = lidar_full_sfx
	$"../AudioStreamPlayer".play()

	var viewport_size = get_viewport().get_texture().get_size()
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.exclude = [get_parent().get_rid()]

	var x_step = viewport_size.x / (sweep_steps_horizontal - 1.0)
	var y_step = viewport_size.y / (sweep_steps_vertical - 1.0)
	var max_offset = 0.5 * min(x_step, y_step)

	var rows_per_frame = 1

	for i in range(0, sweep_steps_vertical, rows_per_frame):
		for k in range(rows_per_frame):
			var new_points_positions := PackedVector3Array()
			var new_points_colors := PackedColorArray()
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
				query.to = ray_origin + ray_direction * ray_length_sweep

				var result = space_state.intersect_ray(query)
				if result:
					# var collider = result.collider
					# NOTE: Jesus Christ
					# if !is_node_in_group_or_parent(collider, "monster"):
					# var is_red = is_node_in_group_or_parent(collider, "red")
					var color := Color(1.0, 1.0, 1.0)

					new_points_positions.push_back(result.position)
					new_points_colors.push_back(color)
			await get_tree().create_timer(0.001).timeout
			update_point_mesh(new_points_positions, new_points_colors)

	$"../AudioStreamPlayer".stop()


func update_point_mesh(points_positions: PackedVector3Array, points_colors: PackedColorArray):
	for i in range(points_positions.size()):
		point_mesh_instance.set_instance_transform(
			mesh_tail, Transform3D(Basis(), points_positions[i])
		)
		point_mesh_instance.set_instance_color(mesh_tail, points_colors[i])
		mesh_tail += 1
		if mesh_tail >= max_mesh_count:
			mesh_tail = 0
