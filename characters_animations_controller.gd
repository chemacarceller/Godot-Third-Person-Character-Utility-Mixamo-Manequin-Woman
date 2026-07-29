class_name  CharactersAnimationsController extends AnimationTree

# Indicating during how many frames must be detected the fall movement happens continuosly 
# until the animation takes place. To avoid short animations changes
@export_range(1,30) var FALLING_FRAMES_DETECTION : int = 5

# We get the state machine of the AnimationTree
@onready var state_machine := get("parameters/playback") as AnimationNodeStateMachinePlayback
var prev_node : StringName = ""
var prev_direction : int = -1

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		MyLogger.info("Saliendo del animation controller",'animations_controller.gd',17, true)

func _ready() -> void :  MyLogger.info(" AnimationController Ready " + name + " ...", 'animations_controller.gd', 19, true)

func _enter_tree() -> void : MyLogger.info(" AnimationController instantiated " + name + " ...", 'animations_controller.gd', 21, true)

# Changing the direction of the movement compoment
func _on_character_movement_component_directionModeChanged(data: int) -> void :
	
	var movementComponent = get_parent().get_movementComponent()
	match data:
		movementComponent.NONE:
			EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed, ["", "None"])
		movementComponent.STRAIFLEFT:
			EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed, ["", "Straif Left"])
		movementComponent.LEFTFOR:
			EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed, ["", "Straif Left and Forward"])
		movementComponent.LEFTBACK:
			EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed, ["", "Straif Left and Backward"])
		movementComponent.STRAIFRIGHT:
			EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed, ["", "Straif Right"])
		movementComponent.RIGHTFOR:
			EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed, ["", "Straif Right and Forward"])
		movementComponent.RIGHTBACK:
			EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed, ["", "Straif Right and Backward"])
		movementComponent.FORWARD:
			EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed, ["", "Forward"])
		movementComponent.BACKWARD:
			EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed, ["", "Backward"])

# Changing the direction of the movement compoment
func _on_character_movement_component_movementStateChanged(data: int) -> void :
	var movementComponent = get_parent().get_movementComponent()
	var isArmed = get_parent().get_isArmed()

	## Setting the animations transitions

	var is_idle : bool = false
	var is_walking : bool = false
	var is_walkingArmed : bool = false
	var is_runing : bool = false
	var is_runingArmed : bool = false
	var is_falling : bool = false
	var is_jumping : bool = false

	is_idle = true if data == movementComponent.IDLE else false
	is_walking = true if data == movementComponent.WALKING and not isArmed  else false
	is_walkingArmed = true if data == movementComponent.WALKING and isArmed else false
	is_runing = true if data == movementComponent.RUNING and not isArmed  else false
	is_runingArmed = true if data == movementComponent.RUNING and isArmed  else false
	is_falling = true if data == movementComponent.FALLING else false
	is_jumping = true if data == movementComponent.JUMPING else false

	## Doing the transitions
	if get("parameters/conditions/idle") != is_idle : 
		set("parameters/conditions/idle",  is_idle)
		if is_idle : EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed,["Idle",""])
	if get("parameters/conditions/walk") != is_walking : 
		set("parameters/conditions/walk",  is_walking)
		if is_walking : EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed,["Walking",""])
	if get("parameters/conditions/walkArmed") != is_walkingArmed : 
		set("parameters/conditions/walkArmed",  is_walkingArmed)
		if is_walkingArmed : EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed,["Walking",""])
	if get("parameters/conditions/run") != is_runing : 
		set("parameters/conditions/run", is_runing)
		if is_runing : EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed,["Runing",""])
	if get("parameters/conditions/runArmed") != is_runingArmed : 
		set("parameters/conditions/runArmed", is_runingArmed)
		if is_runingArmed : EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed,["Runing",""])
	if get("parameters/conditions/fall") != is_falling : 
		set("parameters/conditions/fall", is_falling)
		if is_falling : EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed,["Falling",""])
	if get("parameters/conditions/jump") != is_jumping : 
		set("parameters/conditions/jump", is_jumping)
		if is_jumping : EventBus.emit(self._on_character_movement_component_movementStateChanged, EventBus.EVENT.Movement_Changed,["Jumping",""])
