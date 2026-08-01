# Base script for all characters of this demo; inherits from CharacterBodySkeleton3D, 
# the character itself also inherits from CharacterBodySkeleton3D
@tool
class_name CharactersController extends CharacterBodySkeleton3D

## Indicates if is enabled or not
@export var isEnabled : bool = true :
	set (value) : isEnabled=value
	get() : return isEnabled

# Flag indicating if the character is armed
var _isArmed : bool = false

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		MyLogger.info("Exiting " + name + " ...", 'characters_controller.gd', 27, true)


func _enter_tree() -> void : MyLogger.info(" CharacterController instantiated " + name + " ...", 'characters_controller.gd', 36, true)

func _ready() -> void:
	super()

	MyLogger.info(" CharacterController Ready " + name + " ...", 'characters_controller.gd', 36, true)
	
	# I emit an event to show what movement it has.
	var MovementComponent : CharacterMovementComponent = get_movementComponent()
	if MovementComponent.get_movementState() == MovementComponent.RUNING :
		EventBus.emit(self._ready, EventBus.EVENT.Movement_Changed,["Runing",""])
	elif MovementComponent.get_movementState() == MovementComponent.WALKING :
		EventBus.emit(self._ready, EventBus.EVENT.Movement_Changed,["Walking",""])
	elif MovementComponent.get_movementState() == MovementComponent.IDLE :
		EventBus.emit(self._ready, EventBus.EVENT.Movement_Changed,["Idle",""])

	# Emit event to show which camera mode you are using
	EventBus.emit(self._ready, EventBus.EVENT.CameraMode_Changed, GameInstance._character.get_cameraController().CAMERA_MODE.keys()[GameInstance._character.get_cameraController().cameraMode])


# Inputs resolution, this must be passed to the PlayerController when developed
func _input(_event) -> void:

	if isEnabled :
		# If move_run action changes, the runing variable of the movement modified
		if Input.is_action_pressed("move_run_change") :
			get_movementComponent().set_isRunOrWalk(not get_movementComponent().get_isRunOrWalk(), true)
		elif Input.is_action_pressed("move_run_continuos"):
			get_movementComponent().set_isRunOrWalk(true, false)
		elif Input.is_action_just_released("move_run_continuos"):
			get_movementComponent().set_isRunOrWalk(false, false)

# Adjusting the weapon shape, the weapon shape position and rotation must be translated to the weapon shape included in the character global shape
func _positioning_weaponHull() -> void :
	if _isArmed and isEnabled and get_bone().get_children().size() > 0 :
		get_weaponHull().global_position = get_bone().get_children()[0].get_collisionShape().global_position
		get_weaponHull().global_rotation = get_bone().get_children()[0].get_collisionShape().global_rotation

# PUBLIC API of this Character Getter and Setters methods

# Getting the character components added to the template
func get_bone() -> BoneAttachment3D : return get_node("Armature/Skeleton3D/Bone") as BoneAttachment3D
func get_weaponHull() -> CollisionShape3D : return get_node("WeaponHull") as CollisionShape3D
func get_cameraController() -> Node3D : return find_child("CameraController") as Node3D
func get_movementComponent() -> Node : return get_node("CharacterMovementComponent") as Node

func get_isArmed() -> bool : return _isArmed
func set_isArmed(value : bool) :
	_isArmed = value
	get_animationTree()._on_character_movement_component_movementStateChanged(get_movementComponent().get_movementState())

# Returns the character context, that is the data needed being passed by a character's change
func get_context() -> CharactersData :
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
	
	if _isArmed :
		# The only one child component is the weapon
		# Creating a reference to that and removing the previous reference so that it keeps in memory when the _character is removed
		context.weapon = get_bone().get_children()[0]

	return context

# Setting the character's context
func set_context(context : CharactersData) -> void :
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
