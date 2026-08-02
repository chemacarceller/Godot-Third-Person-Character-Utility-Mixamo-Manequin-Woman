extends Node

# Game's events list (To be filled in)
enum EVENT {
	GraphicProfile_Changed,	# It is launched when the graphic profile changes
	Movement_Changed, 		# It is launched when there is a change in direction or mode of movement
	CameraMode_Changed,		# It is launched when the camera mode is changed
	Time_TicToc 			# It is launched when one second of the game time expires global time controlled by GameInstance
}

# Dictionary to hold event names and their associated listener Callables at a fixed time
var _listeners: Dictionary = {}

# Array to store the history of emitted events to make a historical list when exiting
var emit_history_data: Array[Dictionary] = []

# Function that receives notifications
func _notification(what) :
	# When a game closure is requested
	if what == NOTIFICATION_WM_CLOSE_REQUEST :
		_reset()
		save_event_data()
		MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : " + " Exited ... ", str(self), _get_current_line(23), true)

# It does nothing
func _exit_tree() -> void : pass

# Function that executes first when the node is added to the scene
func _enter_tree() -> void : 

	# Check if the mandatory MyLogger exists
	if has_node("/root/MyLogger") or is_instance_valid(Engine.get_singleton("MyLogger")) :

		var _target = get_node("/root/MyLogger") if has_node("/root/MyLogger") else Engine.get_singleton("MyLogger")
		if _target.has_method("info") and _target.has_method("warn") and _target.has_method("error") :
			MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : " + " Checked the success of MyLogger existence ... ",str(self),_get_current_line(36), true)
		else : 
			print("FRAME : " + str(Engine.get_process_frames()) + " : " + str(self) + " Error: The C++ class MyLogger does not have the appropriate methods")

			# Close the game completely and make sure the script stops running immediately at that point.
			if is_instance_valid(GameInstance) and GameInstance.has_method("_quit_gracefully") : GameInstance._quit_gracefully(false)
			else : get_tree().quit()
	else :

		print("FRAME : " + str(Engine.get_process_frames()) + " : " + str(self) + " Error: The C++ class MyLogger is not registered")

		# Close the game completely and make sure the script stops running immediately at that point.
		if is_instance_valid(GameInstance) and GameInstance.has_method("_quit_gracefully") : GameInstance._quit_gracefully(false)
		else : get_tree().quit()

	MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : " + " Instantiated ... ",str(self),_get_current_line(51), true)


# Function that executes second when the node is added to the scene
func _ready() -> void : MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : " + " Ready ... ",str(self),_get_current_line(55), true)


# Public methods

# Function that allows registering a handler function for an event
func subscribe(event_num: EVENT, listener: Callable) -> void:

	# Geting the event_name
	var event_name = EVENT.keys()[event_num]

	# Register a listener for a specific event
	if not _listeners.has(event_name) : _listeners[event_name] = []
	_listeners[event_name].append(listener)

	# Structure for displaying information
	var listener_info = {
		"object_name": listener.get_object().name if is_instance_valid(listener.get_object()) else "<Invalid Object>",
		"method_name": listener.get_method()
	}

	MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : " + " : Subscribed listener '%s' to event '%s'." % [str(listener_info), event_name], str(self), _get_current_line(76), true)

# Function to unregister an event handler function
func unsubscribe(event_num: EVENT, listener: Callable) -> void:

	# Geting the event_name
	var event_name = EVENT.keys()[event_num]

	# Unregister a listener from a specific event
	if _listeners.has(event_name):
		_listeners[event_name].erase(listener)
		if _listeners[event_name].is_empty() : _listeners.erase(event_name)

	# Structure for displaying information
	var listener_info = {
		"object_name": listener.get_object().name if is_instance_valid(listener.get_object()) else "<Invalid Object>",
		"method_name": listener.get_method()
	}

	MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : " + " : UnSubscribed listener '%s' to event '%s'." % [str(listener_info), event_name], str(self), _get_current_line(95), true)

# Function that emits an event; the function triggering it must be specified, and arguments can be passed to it.
func emit(sender: Callable, event_num: EVENT, args) -> void :

	# Geting the event_name
	var event_name = EVENT.keys()[event_num]
	
	MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : " + " : Emitting event : ( " + str(event_name)  + " ) " + str(sender), str(self), _get_current_line(103), true)
	
	# Emit an event with the given arguments to all registered listeners
	if _listeners.has(event_name) :

		var event_listeners = _listeners[event_name]

		# Duplicate the list to avoid modification during iteration
		var listeners = event_listeners.duplicate()
		for listener in listeners :

			if listener is Callable :

				# Call the listener method with the provided arguments if the object is still alive in memory
				if is_instance_valid(listener.get_object()) : 

					listener.call(args)

					# Obtain information for the historical record
					var timestamp = int(Time.get_unix_time_from_system())
					var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
					var time_str = "%02d:%02d:%02d" % [datetime.hour, datetime.minute, datetime.second]
					var date_str = Time.get_date_string_from_system(false)

					var full_path_listener_str: String = ""
					var full_path_sender_str: String = ""
					var listener_obj = listener.get_object()
					var sender_obj = sender.get_object()
					if is_instance_valid(listener_obj) and listener_obj is Node and listener_obj.is_inside_tree() :
						full_path_listener_str = str(listener_obj.get_path())
					else:
						full_path_listener_str = listener_obj.name if is_instance_valid(listener_obj) else "<Invalid Object>"
					if is_instance_valid(sender_obj) and sender_obj is Node and sender_obj.is_inside_tree() :
						full_path_sender_str = str(sender_obj.get_path())
					else:
						full_path_sender_str = sender_obj.name if is_instance_valid(listener_obj) else "<Invalid Object>"

					var current_delta: float = Engine.get_main_loop().root.get_process_delta_time() * 1000.0

					# Dictionary with information about this execution of this event supervitamined
					var emit_record: Dictionary = {
						"event": event_name,
						"sender_obj": sender_obj.name if sender_obj else "Static",
						"sender_path": full_path_sender_str,
						"sender_method": sender.get_method(),
						"listener_obj": listener_obj.name if listener_obj else "Invalid",
						"listener_path": full_path_listener_str,
						"listener_method": listener.get_method(),
						"args": args,
						"time": time_str,
						"date" : date_str,
						"frame": Engine.get_process_frames(),
						"ticks_msec": Time.get_ticks_msec(),
						"frame_delta_ms" : snapped(current_delta, 0.01),
						"fps" : snapped(1000.0 / current_delta, 0.1) if current_delta > 0 else 0.0
					}

					# We add to the event history log and display the information
					emit_history_data.append(emit_record)
					MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : " + " : Executing handler method : "+ str(emit_record), str(self), _get_current_line(162), true)

				else : 

					# We delete the event handler function because it is invalid since the function object does not exist in memory
					_listeners[event_name].erase(listener)
					MyLogger.error("FRAME : " + str(Engine.get_process_frames()) + " : " + " Event '%s' -> The object associated with the listener does not exist in memory: %s" % [event_name, str(listener)], str(self), _get_current_line(168), true)
			else :

				# We deleted the event handler function because it was invalid since it was not a Callable
				_listeners[event_name].erase(listener)
				MyLogger.error("FRAME : " + str(Engine.get_process_frames()) + " : " + " Event '%s' -> Listener is not a Callable: %s" % [event_name, str(listener)], str(self), _get_current_line(173), true)
	else : MyLogger.warn("FRAME : " + str(Engine.get_process_frames()) + " : " + " Event '%s' but no listeners registered for it." % event_name,str(self),_get_current_line(174), true)


# Function that returns whether a handler function is subscribed to an event
func is_subscribed(event_num: EVENT, listener: Callable) -> bool : 

	var exist : bool = listener in _listeners.get(EVENT.keys()[event_num], [])

	MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : " + " : Listener : " + str(listener)  + " exist in event " + str(EVENT.keys()[event_num]) + " ? " + str(exist), str(self), _get_current_line(182), true)
	return exist


# We clear the dictionary of event handler functions
func _reset() -> void  : 
	_listeners.clear()
	MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : " + " Cleared the listeners dictionary", str(self), _get_current_line(189), true)

# Returns all handler functions registered for a specific event
func get_all_listeners_for_event(event_name: String) -> Array :
	MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : " + " Getting all the listeners for event " + event_name, str(self), _get_current_line(193), true)
	if _listeners.has(event_name) : return _listeners[event_name]
	return []


# Returns the array containing the history of called events
func get_emit_history() -> Array : 
	MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : " + " Getting the event emitted history", str(self), _get_current_line(200), true)
	return emit_history_data

# Stores the history of registered call events
func save_event_data() -> void :

	# The parameter "\t" adds automatic tabs to make the JSON readable (pretty print)
	var json_string = JSON.stringify(emit_history_data, "\t")

	MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : "  + " Printing the historical list of events that have taken place:\n%s" % json_string, str(self), _get_current_line(209), false)

	# We clear the history
	emit_history_data.clear()
	MyLogger.info("FRAME : " + str(Engine.get_process_frames()) + " : "  + " Cleared the historical list of events ", str(self), _get_current_line(213), true)

# If in debug mode, use the stack. If in the .exe, use the fixed value you pass to it.
func _get_current_line(fallback_line : int = 0) -> int :
	if OS.is_debug_build():
		var stack = get_stack()
		if stack.size() > 1: return stack[1].line
	return fallback_line

# Returns the memory used by the game at this moment for event historic
func _get_process_real_ram() -> float :
	
	var output = []
	var pid = OS.get_process_id() 
	
	# --- WINDOWS ---
	if OS.get_name() == "Windows":
		# Executes a silent console query using PowerShell or tasklist
		OS.execute("tasklist", ["/FI", "PID eq %d" % pid, "/FO", "CSV", "/NH"], output)
		if output.size() > 0 and output[0] != "":
			var partes = output[0].split(",")
			if partes.size() > 4:
				var ram_texto = partes[4].replace('"', '').replace(' K', '').replace('.', '').strip_edges()
				var kilobytes = ram_texto.to_int()
				return snapped(kilobytes / 1024.0, 0.01) # Convertido a MB
				
	# --- LINUX / MAC ---
	elif OS.get_name() in ["Linux", "macOS", "FreeBSD"]:
		OS.execute("ps", ["-p", str(pid), "-o", "rss="], output)
		if output.size() > 0 and output[0] != "":
			var kilobytes = output[0].strip_edges().to_int()
			return snapped(kilobytes / 1024.0, 0.01) # Convertido a MB

	return 0.0
