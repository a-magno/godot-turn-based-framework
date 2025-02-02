extends GridContainer

const STATUS_UI = preload("res://ui/status_ui.tscn")

func add_status( status : Status )->void:
	var new_ui = STATUS_UI.instantiate()
	new_ui.status = status
	new_ui.status.status_applied.connect(_on_status_applied)

func _on_status_applied( status : Status )->void:
	if status.can_expire:
		status.duration -= 1
