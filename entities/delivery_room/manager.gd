extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("remove_item"):
			body.remove_item("Chronium")
		else:
			print("O jogador não possui o método 'remove_item'. Certifique-se de que ele está implementado.")
