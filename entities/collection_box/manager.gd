extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("add_item"):
			var item_name = get_parent().get("item_name")
			body.add_item(item_name)
		else:
			print("O jogador não possui o método 'add_item'. Certifique-se de que ele está implementado.")
