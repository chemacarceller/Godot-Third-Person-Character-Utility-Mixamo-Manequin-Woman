@tool
class_name CharactersController extends CharacterBodySkeleton3D

@export var isEnabled : bool = true :
	set (value):
		isEnabled=value
	get():
		return isEnabled

## How much delay before being able to change the runing mode
@export_range(0.1,30) var DELAY_TIME_CHANGE_MODE : float = 3

# Flag indicating if the movement Mode is able to change
var _changeModeEnabled : bool = true

# Flag indicating if the character is armed
var _isArmed : bool = false

var _timer : Timer = null
var _timer2 : Timer = null

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		MyLogger.info("Exiting " + name + " ...", 'characters_controller.gd', 27, true)
		# The timers are continuously working so they must be removed only when the game ends
		if _timer != null : 
			if _timer.is_inside_tree() : remove_child(_timer)
			_timer.queue_free()
			_timer = null
		if _timer2 != null : 
			if _timer2.is_inside_tree() : remove_child(_timer2)
			_timer2.queue_free()
			_timer2 = null

func _enter_tree() -> void : MyLogger.info(" CharacterController instantiated " + name + " ...", 'characters_controller.gd', 36, true)

func _ready() -> void:
	super()
	
	# Timer used to activate the movement mode change
	_timer = Timer.new()

	# Timer used to adjust the weapon shape
	_timer2 = Timer.new()
	
	_timer.timeout.connect(_on_timer_timeout)
	_timer2.timeout.connect(_on_timer_timeout2)
	add_child(_timer)
	add_child(_timer2)
	
	# Instead of adjusting the weapon shape each frame we do each 0.05 seconds 20fps
	_timer2.wait_time = 0.05
	_timer2.start()

	MyLogger.info(" CharacterController Ready " + name + " ...", 'characters_controller.gd', 36, true)
	
	# I emit an event to show what movement it has.
	var MovementComponent : CharacterMovementComponent = GameInstance._character.get_movementComponent()
	if MovementComponent.get_movementState() == MovementComponent.RUNING :
		EventBus.emit(self._ready, EventBus.EVENT.Movement_Changed,["Runing",""])
	elif MovementComponent.get_movementState() == MovementComponent.WALKING :
		EventBus.emit(self._ready, EventBus.EVENT.Movement_Changed,["Walking",""])
	elif MovementComponent.get_movementState() == MovementComponent.IDLE :
		EventBus.emit(self._ready, EventBus.EVENT.Movement_Changed,["Idle",""])

	# Emit event to show which camera mode you are using
	EventBus.emit(self._ready, EventBus.EVENT.CameraMode_Changed, GameInstance._character.get_cameraController().CAMERA_MODE.keys()[GameInstance._character.get_cameraController().cameraMode])


func update_skeleton():
	super()

func update_animationplayer():
	super()

# Inputs resolution, this must be passed to the PlayerController when developed
func _input(_event) -> void:

	if isEnabled :
		# If move_run action changes, the runing variable of the movement modified
		if Input.is_action_pressed("move_run_change") and _changeModeEnabled:
			_changeModeEnabled = false
			get_movementComponent().set_isRunOrWalk(not get_movementComponent().get_isRunOrWalk())
			_timer.wait_time = DELAY_TIME_CHANGE_MODE
			_timer.start()
		elif Input.is_action_pressed("move_run_continuos"):
			get_movementComponent().set_isRunOrWalk(true)
			_changeModeEnabled = true
			if _timer.time_left > 0 : _timer.stop()
		elif Input.is_action_just_released("move_run_continuos"):
			get_movementComponent().set_isRunOrWalk(false)
			_changeModeEnabled = true
			if _timer.time_left > 0 : _timer.stop()

func _on_timer_timeout():
	if isEnabled :
		_changeModeEnabled = true

# Adjusting the weapon shape, the weapon shape position and rotation must be translated to the weapon shape included in the character global shape
func _on_timer_timeout2() -> void:
	if _isArmed and isEnabled and get_bone().get_children().size() >0 :
		get_weaponHull().global_position = get_bone().get_children()[0].get_node("WeaponHull").global_position
		get_weaponHull().global_rotation = get_bone().get_children()[0].get_node("WeaponHull").global_rotation


# PUBLIC API of this Character Getter and setters methods
# All Getters and setters functions

func get_cameraController() -> Node3D:
	return find_child("CameraController") as Node3D

# Only one movement can be assigned and this function retireves it
func get_movementComponent() -> Node:
	return get_node("CharacterMovementComponent") as Node

# returns the character context, that is the data needed being passed by a character's change
func get_context() -> CharactersData:
	var context = CharactersData.new()
	context.position = position
	context.armatureRotation = get_armature().rotation
	context.velocity = velocity

	# getting the movement's component context
	context.movementContext = get_movementComponent().get_context()

	# getting the cameraController context
	context.cameraControllerContext = get_cameraController().get_context()
	
	context.scaleFactor = skeletonScaleFactor
	
	context.isArmed = _isArmed
	
	if _isArmed:
		# The only one child component is the weapon
		# Creating a reference to that and removing the previous reference so that it keeps in memory when the _character is removed
		context.weapon = get_bone().get_children()[0]

	return context

# setting the character's context
func set_context(context : CharactersData) -> void:
	position = context.position
	get_armature().rotation = context.armatureRotation
	velocity = context.velocity

	# setting the movement's component context
	get_movementComponent().set_context(context.movementContext)

	# setting the cameraController's component context
	get_cameraController().set_context(context.cameraControllerContext)
	
	_isArmed = context.isArmed
	
	if _isArmed :
		context.weapon.owner = null
		context.weapon.scale = context.weapon.scale * Vector3(context.scaleFactor.x/skeletonScaleFactor.x, context.scaleFactor.y/skeletonScaleFactor.y, context.scaleFactor.z/skeletonScaleFactor.z)
		context.weapon.reparent(get_bone(), false)
		context.weapon.owner = get_bone().get_owner()
		get_node("WeaponHull").disabled=false

func get_timer() -> Timer :
	return _timer

func get_bone() -> BoneAttachment3D :
	return get_node("Armature/Skeleton3D/Bone")
	
func set_isArmed(value : bool) :
	_isArmed = value
	get_animationTree()._on_character_movement_component_movementStateChanged(get_movementComponent().get_movementState())

func get_isArmed() -> bool :
	return _isArmed

func get_weaponHull() -> CollisionShape3D:
	return get_node("WeaponHull")

func get_animationTree() -> AnimationTree :
	return get_node("AnimationTree")
