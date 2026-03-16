extends CanvasLayer

@onready var console_ui = $ConsoleUI
@onready var output_history = $ConsoleUI/PanelContainer/VBoxContainer/OutputHistory
@onready var command_input = $ConsoleUI/PanelContainer/VBoxContainer/CommandInput

func _ready():
	console_ui.visible = false
	
	command_input.text_submitted.connect(_on_command_input_text_submitted)
	command_input.focus_exited.connect(_on_command_input_focus_exited)
	
	output_history.focus_mode = Control.FOCUS_NONE
	$ConsoleUI/PanelContainer.focus_mode = Control.FOCUS_NONE
	
	_log_message("Dev Console Initialized. Focus Lock Active.")

func _input(event):
	if event.is_action_pressed("toggle_console"):
		_toggle_console()
		get_viewport().set_input_as_handled()

func _toggle_console():
	console_ui.visible = !console_ui.visible
	
	if console_ui.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		command_input.grab_focus()
	else:
		if get_tree().get_first_node_in_group("player"):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		command_input.clear()

func _on_command_input_text_submitted(new_text: String):
	if new_text.is_empty():
		return
		
	_log_message("> " + new_text)
	_process_command(new_text.strip_edges().to_lower())
	
	command_input.clear()
	command_input.call_deferred("grab_focus")

func _on_command_input_focus_exited():
	if console_ui.visible:
		command_input.call_deferred("grab_focus")

func _log_message(message: String):
	if output_history:
		output_history.append_text(message + "\n")
	print("[Console] " + message)

func _process_command(input: String):
	var parts = input.split(" ")
	var command = parts[0]
	
	match command:
		"/help":
			_log_message("Available: /help, /reload, /seed, /quit")
		"/reload":
			_log_message("Reloading current scene...")
			get_tree().reload_current_scene()
		"/seed":
			_log_message("Current World Seed: " + str(WorldStateManager.world_seed))
		"/quit":
			get_tree().quit()
		_:
			_log_message("Unknown command: " + command)
