class_name RacerPalmsScatter
extends MultiMeshInstance3D
## Scatters many palms of one variant with a single MultiMeshInstance3D
## (one draw call per variant). Wind and colour variation keep working,
## because the palm shader derives everything per instance on the GPU.
##
## For your own vegetation system you can skip the node and only call
## RacerPalmsScatter.build_multimesh(mesh, transforms).

enum Variant { COASTAL, TALL, WINDBLOWN }

const MESHES := {
	Variant.COASTAL: ["res://racer_palms/meshes/racer_palm_coastal.obj", "res://racer_palms/meshes/racer_palm_coastal_lod1.obj"],
	Variant.TALL: ["res://racer_palms/meshes/racer_palm_tall.obj", "res://racer_palms/meshes/racer_palm_tall_lod1.obj"],
	Variant.WINDBLOWN: ["res://racer_palms/meshes/racer_palm_windblown.obj", "res://racer_palms/meshes/racer_palm_windblown_lod1.obj"],
}
const PALM_MATERIAL: ShaderMaterial = preload("res://racer_palms/materials/racer_palm_material.tres")

@export var variant: Variant = Variant.COASTAL
## Use the reduced far-distance mesh (about 1/3 of the triangles).
@export var use_lod1: bool = false
@export_range(1, 20000) var count: int = 200
## Size of the rectangular area (X/Z) around this node.
@export var area_size: Vector2 = Vector2(200.0, 200.0)
@export var min_scale: float = 0.85
@export var max_scale: float = 1.15
@export var random_seed: int = 1


func _ready() -> void:
	rebuild()


## Regenerates the instances from the exported settings.
func rebuild() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var transforms: Array[Transform3D] = []
	transforms.resize(count)
	for i in count:
		var s := rng.randf_range(min_scale, max_scale)
		var rot := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(s, s, s))
		var pos := Vector3(
				rng.randf_range(-0.5, 0.5) * area_size.x, 0.0,
				rng.randf_range(-0.5, 0.5) * area_size.y)
		transforms[i] = Transform3D(rot, pos)
	multimesh = build_multimesh(get_mesh(variant, use_lod1), transforms)
	material_override = PALM_MATERIAL
	extra_cull_margin = 1.5


static func get_mesh(palm_variant: Variant, lod1: bool = false) -> Mesh:
	return load(MESHES[palm_variant][1 if lod1 else 0]) as Mesh


## Builds a MultiMesh for the given palm mesh and local transforms.
## Remember to set material_override = RacerPalmsWind.get_material()
## on the MultiMeshInstance3D that uses it.
static func build_multimesh(mesh: Mesh, transforms: Array[Transform3D]) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	return mm
