# vim: set noexpandtab tabstop=4 shiftwidth=4 softtabstop=4:

extends CharacterBody3D

@export var velocity_component: Node3D
@export var camera_component: Camera3D

@onready var player_collision = get_node("CollisionShape3D")
@onready var inventory_texture = get_node("Inventário/Control/Item")
@onready var inventory_label = get_node("Inventário/Control/Label")
@onready var objective = get_node("Objetivo/Control/Label")
@onready var extraction_area = get_node("/root/Map-01/Extração/ExtractionArea")
@onready var static_body_extraction = get_node("/root/Map-01/Extração/ExtractionArea/StaticBody3D")
var inventory: Array = ["Chronium"]
var delivered: bool = false

# @onready var Spawner = get_parent().get_node("Spawner")
# @onready var hud = get_node("HUD")

# signal respawn

func _ready():
  # if not is_multiplayer_authority(): return
	if extraction_area.is_in_group("green"):
		extraction_area.remove_from_group("green")
		print("Grupo 'green' removido de ExtractionArea.")

	if static_body_extraction.is_in_group("green"):
		static_body_extraction.remove_from_group("green")
		print("Grupo 'green' removido de StaticBody3D.")
	camera_component.make_current()
	# Set sprite invisible for the current camera
	# get_node("Sprite").visible = fals

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func add_item(item_name: String) -> void:
	if inventory.size() < 1:
		inventory.append(item_name)
		update_inventory_display()
		objective.text = "Entregue o Chronium coletado"
		print("Inventário atualizado: ", inventory)

func remove_item(item_name: String) -> void:
	if inventory.size() == 1:
		inventory.erase(item_name)
		objective.text = "Vá para a nave"
		update_inventory_display()
		print("Item removido. Inventário atualizado: ", inventory)
		canLeave()

func update_inventory_display() -> void:
	if inventory.size() > 0:
		inventory_texture.visible = true
		inventory_label.visible = true
		inventory_label.text = inventory[0] 
	else:
		inventory_texture.visible = false
		inventory_label.visible = false

func canLeave() -> void:
	delivered = true
	if extraction_area:
		extraction_area.add_to_group("green")
		static_body_extraction.add_to_group("green")

func _physics_process(_delta):
  # if not is_multiplayer_authority(): return

  # if position.y < 0:
  #   position.y = 10

	velocity_component.move(self)
