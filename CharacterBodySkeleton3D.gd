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

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		queue_free()

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


func _ready() -> void:
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING


# PUBLIC API of this CharacterBodySkeleton3D -> Getter and setters methods

func get_armature() -> Node3D:
	return get_node("Armature") as Node3D

func get_animationTree() -> AnimationTree:
	return get_node("AnimationTree") as AnimationTree

func get_animationPlayer() -> AnimationPlayer:
	return get_node("AnimationPlayer") as AnimationPlayer

func get_collisionHull() -> CollisionShape3D:
	return get_node("CollisionHull") as CollisionShape3D

func get_skeleton3d() -> Skeleton3D:
	return get_node("Armature/Skeleton3D") as Skeleton3D
