# Class acting as a template for creating a character
# It consists of a Node3D containing a Skeleton3D as a child, where the character's skeleton will be placed.
# It consists of a CollisionHull, which is a CollisionShape3D of the CapsuleSphere type by default.
# It consists of an AnimationPlayer and an AnimationTree.
@tool
class_name CharacterBodySkeleton3D extends CharacterBody3D

@export var skeletonScaleFactor : Vector3 = Vector3.ZERO :
	set (value):
		skeletonScaleFactor = value
		update_skeleton()

@export var theSkeleton : PackedScene:
	set (value):
		theSkeleton = value
		update_skeleton()

@export var theAnimationPlayer : PackedScene :
	set (value):
		theAnimationPlayer = value
		update_animationplayer()

func _ready() -> void :	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING

func _notification(what) : if what == NOTIFICATION_WM_CLOSE_REQUEST : queue_free()

# Private Methods - Should not be called from outside; intended for use only during updates.
# the skeleton, skeletonScaleFactor, or AnimationPlayer in the editor of the class inheriting from this template

func update_skeleton():
	if theSkeleton != null :
		var skeletonNode : Skeleton3D = theSkeleton.instantiate()
		skeletonNode.scale = skeletonScaleFactor
		skeletonNode.name="Skeleton3D"
		get_node("Armature/Skeleton3D").queue_free()
		get_node("Armature/Skeleton3D").replace_by(skeletonNode)

func update_animationplayer():
	if theAnimationPlayer != null:
		var animationPlayerNode : AnimationPlayer = theAnimationPlayer.instantiate()
		get_node("AnimationPlayer").queue_free()
		get_node("AnimationPlayer").replace_by(animationPlayerNode)


# PUBLIC API of this CharacterBodySkeleton3D -> Getter and setters methods
func get_armature() -> Node3D : return get_node("Armature") as Node3D
func get_skeleton3d() -> Skeleton3D : return get_node("Armature/Skeleton3D") as Skeleton3D
func get_collisionHull() -> CollisionShape3D : return get_node("CollisionHull") as CollisionShape3D
func get_animationPlayer() -> AnimationPlayer : return get_node("AnimationPlayer") as AnimationPlayer
func get_animationTree() -> AnimationTree : return get_node("AnimationTree") as AnimationTree
