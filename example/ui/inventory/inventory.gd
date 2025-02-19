extends Control
class_name InventoryUI

const INVENTORY = preload("res://example/ui/inventory/inventory.tscn")
static var inventory_open : bool = false

static func open_inventory()->InventoryUI:
	if inventory_open: return
	var new_inventory : InventoryUI = INVENTORY.instantiate()
	new_inventory.visibility_changed.connect(new_inventory._on_visibility_changed)
	new_inventory.show()
	inventory_open = true
	return new_inventory

static func close_inventory( inventory : Control)->void:
	if not inventory_open: return
	inventory_open = false
	inventory.hide()
	inventory.visibility_changed.disconnect(inventory._on_visibility_changed)
	inventory.queue_free()

func _on_visibility_changed()->void:
	if inventory_open:
		populate_items()
	else:
		%ItemIcon.texture = null
		%ItemTooltip.text = ""

func populate_items()->void:
	%ItemList.clear()
	if GameManager.PLAYER.inventory.is_empty(): return
	for item : Item in GameManager.PLAYER.inventory:
		var string = "%dx %s" % [item.stack, item.id.capitalize()]
		%ItemList.add_item(string, item.icon, false)
		%ItemList.set_item_metadata( %ItemList.item_count-1, item )

func _on_item_activated(index: int) -> void:
	var item = %ItemList.get_item_metadata( index )
	GameManager.event.combat_item_selected.emit( item )

func _on_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	var item : Item = %ItemList.get_item_metadata( index )
	%ItemIcon.texture = item.icon
	%ItemTooltip.text = item.tooltip
	
