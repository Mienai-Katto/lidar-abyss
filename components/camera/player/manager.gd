extends Camera3D

@export var ray_count: int = 8000  # Number of rays to cast
@export var ray_length: float = 100.0  # Max ray length
@export var highlight_duration: float = 3.0
@export var block_color: Color = Color(1, 1, 1, 0.8)

func _input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        create_ray_shower()

func create_ray_shower():
    for i in range(ray_count):
        # Random ray direction
        var ray_direction = Vector3(
            randf_range(-1, 1),
            randf_range(-1, 1),
            randf_range(-1, 1)
        ).normalized()

        var ray_origin = global_position
        var ray_target = ray_origin + ray_direction * ray_length

        var space_state = get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
        var result = space_state.intersect_ray(query)

        if result:
            create_highlight_block(result.position)

func create_highlight_block(_position: Vector3):
    var block = MeshInstance3D.new()
    var mesh = BoxMesh.new()

    mesh.size = Vector3(0.01, 0.01, 0.01)
    block.mesh = mesh
    block.position = _position

    var material = StandardMaterial3D.new()
    material.albedo_color = block_color
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.emission_enabled = true
    material.emission = block_color

    block.material_override = material
    get_parent().add_child(block)

    # Remove block after duration
    await get_tree().create_timer(highlight_duration).timeout
    block.queue_free()
