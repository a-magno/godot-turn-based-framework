extends TextureRect

var status : Status #: set = set_status

@onready var duration: Label = %Duration
@onready var stacks: Label = %Stacks

func set_status(new_status: Status) -> void:
	#if not is_node_ready():
		#await ready
	#
	status = new_status
	texture = status.icon
	duration.visible = status.stack_type == Status.Stack.DURATION
	stacks.visible = status.stack_type == Status.Stack.INTENSITY
	custom_minimum_size = size
	
	if duration.visible:
		custom_minimum_size = duration.size + duration.position
	elif stacks.visible:
		custom_minimum_size = stacks.size + stacks.position
	
	if not status.status_changed.is_connected(_on_status_changed):
		status.status_changed.connect(_on_status_changed)
	
	_on_status_changed()

func _on_status_changed() -> void:
	if not status:
		return

	if status.can_expire and status.duration <= 0:
		queue_free()
		
	if status.stack_type == Status.Stack.INTENSITY and status.stacks == 0:
		queue_free()

	duration.text = str(status.duration)
	stacks.text = str(status.stacks)
