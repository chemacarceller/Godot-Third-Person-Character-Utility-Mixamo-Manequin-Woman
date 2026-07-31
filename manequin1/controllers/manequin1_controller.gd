# Character manequin1 inherits from CharacterBodySkeleton3D
@tool
class_name Manequin1Controller extends CharactersController

@export var running_rotation : Vector3 = Vector3(180, 0, -98)
@export var walking_rotation : Vector3 = Vector3(180, -5, -112)
@export var idle_rotation : Vector3 = Vector3(200, 0, -98)
