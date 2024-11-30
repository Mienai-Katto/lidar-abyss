extends Camera3D

@export var scan_range: float = 900.0
@export var scan_interval: float = 0.5
@export var ray_count: int = 200
@export var ray_length: float = 100.0

func _ready():
  pass
  # if not get_parent().is_multiplayer_authority(): return

func _input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        perform_environment_scan()

func perform_environment_scan():
  # Use camera's forward direction as the base
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
          spawn_temporary_cube(result.position)

func spawn_temporary_cube(position: Vector3):
    var mesh_instance = MeshInstance3D.new()
    var cube_mesh = BoxMesh.new()

    # Create material
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1, 1, 1, 0.5)  # Random translucent color

    # Configure mesh
    cube_mesh.size = Vector3(0.1, 0.1, 0.1)  # Small cube
    mesh_instance.mesh = cube_mesh
    mesh_instance.material_override = material

    # Position and add to scene
    get_tree().root.add_child(mesh_instance)
    mesh_instance.global_transform.origin = position

    # Remove cube after interval
    await get_tree().create_timer(scan_interval).timeout
    mesh_instance.queue_free()