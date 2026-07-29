# structure to store the character's context data

class_name CharactersData extends RefCounted

var position : Vector3 = Vector3.ZERO
var armatureRotation : Vector3 = Vector3.ZERO
var velocity : Vector3 = Vector3.ZERO
var movementContext : CharacterMovementData = null
var cameraControllerContext : CameraControllerData = null
var isArmed : bool = false
var weapon : Weapon = null
var scaleFactor : Vector3 = Vector3.ZERO
