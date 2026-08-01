# Static Class that acts as a bypass to the C++ LogFileWriter class exported as a singleton MyLogger object
# LogFileWriter is created as a singleton onject directly in C++
# This is implemented to prevent errors when rebuilding the project in Godot without .godot folder
extends Node
class_name MyLogger


# --- ANALYZER SHIELD (EDIT TIME) ---
# Static functions corresponding to the public functions of the C++ LogFileWriter class
static func debug(a=null, b=null, c=null, d=null) -> void : _route_call("debug", [a, b, c, d])
static func info(a=null, b=null, c=null, d=null) -> void : _route_call("info", [a, b, c, d])
static func error(a=null, b=null, c=null, d=null) -> void : _route_call("error", [a, b, c, d])
static func warn(a=null, b=null, c=null, d=null) -> void : _route_call("warn", [a, b, c, d])
static func fatal(a=null, b=null, c=null, d=null) -> void : _route_call("fatal", [a, b, c, d])
static func _log_internal(a=null, b=null, c=null, d=null, e=null) -> void : _route_call("_log_internal", [a, b, c, d, e])
static func log_gd(a=null, b=null, c=null, d=null, e=null) -> void : _route_call("log_gd", [a, b, c, d, e])
static func resetLogFile() -> void : _route_call("resetLogFile", [])
static func set_min_level(a=null) -> void : _route_call("set_min_level", [a])
static func get_singleton() -> void : _route_call("get_singleton", [])	

# --- SELF-DESTRUCT INTERCEPTOR ---
# Function to release the MyLogger object
# Function not required; a static class is a resource that releases itself.
# and the singleton object exported from the C++ LogFileWriter class automatically frees itself, as programmed within the module itself
# You cannot use the name 'free'. Since all classes ultimately inherit from Object, your script already possesses a native instance method called 'free()' to remove itself from memory.
static func freeing() -> void :
	# If C++ is active, we let C++ manage its own memory
	# If it happens ahead of time, we simply prevent it from breaking the game
	if Engine.has_singleton("MyLogger") : pass
	else : pass

# --- DYNAMIC ROUTER (GAME TIME) ---
# Function that implements the bypass targeted by this static class
static func _route_call(method_name: String, args: Array) -> void :
	if Engine.has_singleton("MyLogger") :
		var singleton = Engine.get_singleton("MyLogger")
		var clean_args = args.filter(func(element): return element != null)
		singleton.callv(method_name, clean_args)
	else : print("[Early Object " + method_name.to_upper() + "]: ", args)
