# Base script for all characters of this demo; inherits from CharacterBodySkeleton3D, 
# the character itself also inherits from CharacterBodySkeleton3D
@tool
class_name CharactersController extends CharacterBodySkeleton3D

## Indicates if is enabled or not
@export var isEnabled : bool = true :
	set (value) : isEnabled=value
	get() : return isEnabled

@export var running_rotation : Vector3 = Vector3(185, -5, -97)
@export var walking_rotation : Vector3 = Vector3(180, -5, -112)
@export var idle_rotation : Vector3 = Vector3(185, -5, -97)

# Flag indicating if the character is armed
var _isArmed : bool = false

# The weapon of the character
var _weapon : Area3D = null

func _notification(what) : 
	if what == NOTIFICATION_WM_CLOSE_REQUEST : MyLogger.info("Exiting " + name + " ...", 'characters_controller.gd', 22, true)

	# To ensure that references are maintained correctly when synchronizing collision shapes
	if what == NOTIFICATION_POST_ENTER_TREE : if _isArmed : adjusting_collisionShape.call_deferred()
		
func _enter_tree() -> void : MyLogger.info(" CharacterController instantiated " + name + " ...", 'characters_controller.gd', 22, true)

func _ready() -> void :

	super()

	MyLogger.info(" CharacterController Ready " + name + " ...", 'characters_controller.gd', 28, true)

	# Emitting an event to show what movement it has.
	var MovementComponent : CharacterMovementComponent = get_movementComponent()
	if MovementComponent.get_movementState() == MovementComponent.RUNING :
		EventBus.emit(self._ready, EventBus.EVENT.Movement_Changed,["Runing",""])
	elif MovementComponent.get_movementState() == MovementComponent.WALKING :
		EventBus.emit(self._ready, EventBus.EVENT.Movement_Changed,["Walking",""])
	elif MovementComponent.get_movementState() == MovementComponent.IDLE :
		EventBus.emit(self._ready, EventBus.EVENT.Movement_Changed,["Idle",""])

	# Emit event to show which camera mode you are using
	EventBus.emit(self._ready, EventBus.EVENT.CameraMode_Changed, get_cameraController().CAMERA_MODE.keys()[get_cameraController().cameraMode])


# Shooting ACTION
# Indicates if it is the weapon is allowed to fire
var _isFireEnabled : bool = true

func _input(_event) -> void:

	if isEnabled :
		# If move_run action changes, the runing variable of the movement modified
		if InputMap.has_action("move_run_change") and Input.is_action_pressed("move_run_change") :
			get_movementComponent().set_isRunOrWalk(not get_movementComponent().get_isRunOrWalk(), true)
		elif InputMap.has_action("move_run_continuos") and Input.is_action_pressed("move_run_continuos"):
			get_movementComponent().set_isRunOrWalk(true, false)
		elif InputMap.has_action("move_run_continuos") and Input.is_action_just_released("move_run_continuos"):
			get_movementComponent().set_isRunOrWalk(false, false)
			
		if _isArmed : 

			var move_comp = get_movementComponent()
			if move_comp != null :

				if move_comp.get_isMoving() and not move_comp.get_isJumping() and not move_comp.get_isFalling() :

					# I wanted to use is_action_just_pressed but it doesnt work perfectly, instead i use is_action_pressed and make my own code to convert
					if InputMap.has_action("fire") and _event.is_action_pressed("fire") and _isFireEnabled :

						# Firing an semi-automatic weapon need to release the button to fire again
						# The weapon must implement a fire() method
						if _weapon and _weapon.has_method("fire") : 
							_weapon.fire()

							# Disable the fire system until the button is released
							_isFireEnabled = false

					# When the button is released we can fire again
					if InputMap.has_action("fire") and Input.is_action_just_released("fire") and not _isFireEnabled : _isFireEnabled = true


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

	# We create the object of the character's context
	var context = CharactersData.new()

	context.position = position
	context.armatureRotation = get_armature().rotation
	context.velocity = velocity

	# Getting the movement's component context
	context.movementContext = get_movementComponent().get_context()

	# getting the cameraController context
	context.cameraControllerContext = get_cameraController().get_context()
	
	context.scaleFactor = skeletonScaleFactor
	
	context.isArmed = _isArmed

	# The only one child component is the weapon
	# Creating a reference to that and removing the previous reference so that it keeps in memory when the _character is removed
	if _isArmed : context.weapon = get_bone().get_children()[0]
	else : context.weapon = null

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
	
	if _isArmed and context and context.weapon :

		context.weapon.owner = null

		# Prevent division by zero error
		var s_scale = skeletonScaleFactor if skeletonScaleFactor else Vector3.ONE
		var c_scale = context.scaleFactor if context.scaleFactor else Vector3.ONE

		# Calculate the new scale safely
		var target_scale = Vector3(
			c_scale.x / s_scale.x if s_scale.x != 0 else 1.0,
			c_scale.y / s_scale.y if s_scale.y != 0 else 1.0,
			c_scale.z / s_scale.z if s_scale.z != 0 else 1.0 )

		context.weapon.scale *= target_scale
		attach_weapon(context.weapon, false)


# This function is used to attach a weapon to the character.
# The weapon that must be a Area3D that includes a MeshInstance and a CollisionShape with a remoteTransform3D node as achild
# Weapon's methods get_collisionShape() and get_remoteTransform() must be implemented
# It is only used when the weapon is captured from the scene
func attach_weapon(weapon : Area3D, keepGlobalTransform : bool = true) -> void :

	_weapon = weapon

	# Validate that the weapon and movement component exist
	var movement_comp = get_movementComponent()
	if not _weapon or not movement_comp :
		MyLogger.error("Error: _weapon or movementComponent is not assigned", 'characters_controller.gd', 163, true)
		return

	# Validate that the target bone exists
	var bone : BoneAttachment3D = get_bone()
	if not bone :
		MyLogger.error("Error: The BoneAttachment3D node was not found", 'characters_controller.gd', 169, true)
		return

	# Attaching the weapon
	_weapon.reparent(bone, keepGlobalTransform)

	# Indicating that the owner of the weapon is the character
	_weapon.owner = self

	# Indicating the character is armed
	set_isArmed(true)

	# Adjusting the weapon rotation and position to the character and movement
	_onWeaponPositionAdjusting(movement_comp.get_movementState())

	# Adjusting the weapon shape rotation and position explained in the function itself
	adjusting_collisionShape()


# Matches the collisionShape of the character (part of the weapon) to the collisionShape of the attached weapon
# Due to a bug in Godot, when an object is attached with a collisionShape, it does not become part of the collisionShape of the original object.
# The limitation arises because only the collision shapes at the root node level are evaluated.
# The trick is to have added a CollisionShape to the character at the root node level and match it with the weapon's.
func adjusting_collisionShape() :
	
	# Securely validate the weapon subnodes (Collision, RemoteTransform, Hull)
	var weapon_collision = _weapon.get_collisionShape() if _weapon.has_method("get_collisionShape") else null
	var weapon_remote = _weapon.get_remoteTransform() if _weapon.has_method("get_remoteTransform") else null
	var weapon_hull = get_weaponHull()

	if weapon_collision and weapon_hull :
		# We disabled the weapon's collision hull; it's not really necessary.
		weapon_collision.call_deferred("set", "disabled", true)
		
		# We match the shapes
		if weapon_collision.shape : weapon_hull.shape = weapon_collision.shape

	if weapon_remote and weapon_hull :
		# We match the position and rotation of the collisionShapes
		weapon_remote.position = Vector3.ZERO
		weapon_remote.rotation = Vector3.ZERO
		weapon_remote.use_global_coordinates = true
		weapon_remote.update_position = true
		weapon_remote.update_rotation = true
		weapon_remote.update_scale = true
		weapon_remote.remote_path = weapon_hull.get_path()




# Adjusting the AssaultRifle1 depending on the character who takes this weapon

# For doing smooth movement
var tween : Tween = null

# This function adjusts the weapon rotation and position when the weapon is captured
# based on the character and the type of movement they are making
# Called once the weapon is cached and when a movement type is changed
func _onWeaponPositionAdjusting(value : int) -> void :

	# Validate initial states and existence of the weapon
	if not (isEnabled and _isArmed and _weapon) : return

	# Validate that the movement component exists
	var movement_comp = get_movementComponent()
	if not movement_comp :
		MyLogger.error("Error: movementComponent not found in _onWeaponPositionAdjusting", 'characters_controller.gd', 227, true)
		return

	# Weapon rotation and position
	var target_rotation: Vector3 = Vector3.ZERO
	var target_position: Vector3 = Vector3.ZERO

	# Depending on the type of movement, the rotation defined for each character is applied.
	if value == movement_comp.RUNING : target_rotation = running_rotation
	elif value == movement_comp.WALKING : target_rotation = walking_rotation
	elif value == movement_comp.IDLE : target_rotation = idle_rotation
	else : return

	## We convert the degrees of the configuration to radians
	var target_rad = Vector3(
		deg_to_rad(target_rotation.x), 
		deg_to_rad(target_rotation.y), 
		deg_to_rad(target_rotation.z))

	# Option A: Instantaneous movement
	# _weapon.rotation = target_rad
	_weapon.position = target_position

	# Option B: Smooth movement (Much better visually)
	# Safely validate if the previous tween is still active before killing it
	if tween and tween.is_valid() : tween.kill() 
	
	# Create the new Tween associated with this node so that it is automatically cleaned
	tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(_weapon, "rotation", target_rad, 0.1).set_trans(Tween.TRANS_SINE)
