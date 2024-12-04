extends Camera3D

@export var scan_range: float = 900.0
@export var scan_interval: float = 8.5
@export var ray_count: int = 500
@export var ray_length: float = 10.0

@export var highlight_size: Vector2 = Vector2(0.02, 0.02)  # For plane size

@export var sweep_steps_horizontal: int = 100
@export var sweep_steps_vertical: int = 100
# Removed row_delay since we're eliminating delays

func _ready():
    pass

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			perform_environment_scan()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			perform_full_sweep()

func perform_environment_scan():
<<<<<<< HEAD
	var camera_forward = -global_transform.basis.z

	for i in range(ray_count):
		var ray_direction = camera_forward.rotated(Vector3.UP, randf_range(-PI/4, PI/4))
		ray_direction = ray_direction.rotated(Vector3.RIGHT, randf_range(-PI/4, PI/4))
		ray_direction = ray_direction.normalized()
=======
    # Use camera's forward direction as the base
    var camera_forward = -global_transform.basis.z

    for i in range(ray_count):
        # Create a cone of rays in front of the camera
        var ray_direction = camera_forward.rotated(Vector3.UP, randf_range(-PI/4, PI/4))
        ray_direction = ray_direction.rotated(Vector3.RIGHT, randf_range(-PI/4, PI/4))
        ray_direction = ray_direction.normalized()
>>>>>>> 5882129c12747d8bf2e40e633642d5e70cc24524

		var ray_origin = global_position
		var ray_target = ray_origin + ray_direction * ray_length

		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
		query.exclude = [get_parent().get_rid()]
		var result = space_state.intersect_ray(query)

		if result:
			var collider = result.collider
			var is_red = is_node_in_group_or_parent(collider, "red")
			spawn_temporary_cube(result.position, is_red)

func perform_full_sweep():
	var viewport_size = get_viewport().get_texture().get_size()
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.exclude = [get_parent().get_rid()]

	var x_step = viewport_size.x / (sweep_steps_horizontal - 1.0)
	var y_step = viewport_size.y / (sweep_steps_vertical - 1.0)
	var max_offset = 0.5 * min(x_step, y_step)

    var rows_per_iteration = 20  # Adjust this value for speed
    for i in range(0, sweep_steps_vertical, rows_per_iteration):
        for row_offset in range(rows_per_iteration):
            var current_row = i + row_offset
            if current_row >= sweep_steps_vertical:
                break
            var y = (current_row / (sweep_steps_vertical - 1.0)) * viewport_size.y
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
                    spawn_temporary_cube(result.position, is_red)
            # Yield to the engine after processing multiple rows
            await get_tree().process_frame

func spawn_temporary_cube(position: Vector3, is_red: bool):
    var mesh_instance = MeshInstance3D.new()
    var quad_mesh = QuadMesh.new()

    # Create material
    var material = StandardMaterial3D.new()
    if is_red:
        material.albedo_color = Color(1, 0, 0, 0.5)  # Red translucent color
        material.emission_enabled = true  # Enable emission
        material.emission = Color(1, 0, 0, 1)
    else:
        material.albedo_color = Color(1, 1, 1, 0.5)  # White translucent color
        material.emission_enabled = true  # Enable emission
        material.emission = Color(1, 1, 1, 1)

    # Set the material to billboard mode so the plane always faces the camera
    material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

    # Configure mesh
    quad_mesh.size = highlight_size
    mesh_instance.mesh = quad_mesh
    mesh_instance.material_override = material

	# Position and add to scene
	get_tree().root.add_child(mesh_instance)
	mesh_instance.global_transform.origin = position

    # Remove plane after interval
    await get_tree().create_timer(scan_interval).timeout
    mesh_instance.queue_free()

func is_node_in_group_or_parent(node: Node, group_name: String) -> bool:
    var current_node = node
    while current_node != null:
        if current_node.is_in_group(group_name):
            return true
        current_node = current_node.get_parent()
    return false
