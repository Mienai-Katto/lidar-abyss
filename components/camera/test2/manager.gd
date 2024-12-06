extends Camera3D

@export var scan_range: float = 900.0
@export var scan_interval: float = 8.5
@export var ray_count: int = 500
@export var ray_length: float = 100.0
@export var sweep_steps_horizontal: int = 100
@export var sweep_steps_vertical: int = 100
@export var point_size: float = 0.01
@export var highlight_size: Vector2 = Vector2(0.02, 0.02)

var multi_mesh_instance: MultiMeshInstance3D
var points_data = []

func _ready():
  multi_mesh_instance = MultiMeshInstance3D.new()
  var quad_mesh = QuadMesh.new()
  quad_mesh.size = highlight_size

  var multi_mesh = MultiMesh.new()
  multi_mesh.mesh = quad_mesh
  multi_mesh.use_colors = true
  multi_mesh.transform_format = MultiMesh.TRANSFORM_3D

  multi_mesh_instance.multimesh = multi_mesh
  get_tree().get_root().add_child.call_deferred(multi_mesh_instance)

func _input(event):
  if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
      perform_environment_scan()
    elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        perform_full_sweep()

func _process(delta):
    var points_updated = false
    for point in points_data:
        point["time_left"] -= delta
        if point["time_left"] <= 0:
            points_updated = true

    if points_updated:
        points_data = points_data.filter(filter_by_time_left)
        update_multimesh()

func filter_by_time_left(p):
  return p["time_left"] > 0

func perform_environment_scan():
  var camera_forward = -global_transform.basis.z

  for i in range(ray_count):
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
      points_data.append({
        "position": result.position,
        "is_red": is_red,
        "time_left": scan_interval,
      })

    update_multimesh()

func perform_full_sweep():
  var viewport_size = get_viewport().get_texture().get_size()
  var space_state = get_world_3d().direct_space_state
  var query = PhysicsRayQueryParameters3D.new()
  query.exclude = [get_parent().get_rid()]

  var x_step = viewport_size.x / (sweep_steps_horizontal - 1.0)
  var y_step = viewport_size.y / (sweep_steps_vertical - 1.0)
  var max_offset = 0.5 * min(x_step, y_step)

  for i in range(sweep_steps_vertical):
    var y = (i / (sweep_steps_vertical - 1.0)) * viewport_size.y
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
          points_data.append({ "position": result.position, "is_red": is_red, "time_left": scan_interval })
        update_multimesh()

func update_multimesh():
  var mm = multi_mesh_instance.multimesh
  mm.instance_count = points_data.size()
  for i in range(mm.instance_count):
    var point = points_data[i]
    var transform = Transform3D(Basis(), point.position)
    mm.set_instance_transform(i, transform)
    var color = Color(1, 0, 0, 0.5) if point.is_red else Color(1, 1, 1, 0.5)
    mm.set_instance_color(i, color)

func is_node_in_group_or_parent(node: Node, group_name: String) -> bool:
  var current_node = node
  while current_node != null:
    if current_node.is_in_group(group_name): return true
    current_node = current_node.get_parent()
  return false