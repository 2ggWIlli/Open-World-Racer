class_name RacerPalmsWind
extends Node
## Global wind control for all Racer Palms.
##
## All palms share one ShaderMaterial (racer_palm_material.tres), and the wind
## animation runs entirely on the GPU. Changing a value here updates every palm
## (MeshInstance3D and MultiMeshInstance3D) at once - no per-frame CPU work.
##
## Usage without a node:
##     RacerPalmsWind.set_wind(1.5, Vector2(1, 0.2))
##     RacerPalmsWind.set_weather(0.8)   # 0 = calm .. 1 = storm
##     RacerPalmsWind.set_wind_enabled(false)
##
## Or add this script as a node and edit the exported values.

const PALM_MATERIAL: ShaderMaterial = preload("res://racer_palms/materials/racer_palm_material.tres")

@export var wind_enabled: bool = true:
	set(value):
		wind_enabled = value
		_apply()
@export_range(0.0, 3.0, 0.01) var wind_strength: float = 1.0:
	set(value):
		wind_strength = value
		_apply()
@export_range(0.0, 4.0, 0.01) var wind_speed: float = 1.0:
	set(value):
		wind_speed = value
		_apply()
## Wind direction on the ground plane (x = world X, y = world Z).
@export var wind_direction: Vector2 = Vector2(1.0, 0.3):
	set(value):
		wind_direction = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_inside_tree():
		return
	set_wind_enabled(wind_enabled)
	set_wind(wind_strength, wind_direction, wind_speed)


## Sets strength (0 = no movement), direction and animation speed for all palms.
static func set_wind(strength: float, direction: Vector2 = Vector2(1.0, 0.3), speed: float = 1.0) -> void:
	PALM_MATERIAL.set_shader_parameter("wind_strength", maxf(strength, 0.0))
	PALM_MATERIAL.set_shader_parameter("wind_speed", maxf(speed, 0.0))
	if direction.length_squared() > 0.0001:
		PALM_MATERIAL.set_shader_parameter("wind_direction", direction.normalized())


## Turns the wind animation completely on or off (off = static palms, cheapest).
static func set_wind_enabled(enabled: bool) -> void:
	PALM_MATERIAL.set_shader_parameter("wind_enabled", enabled)


## Maps a single weather value from the game (0 = calm, 1 = storm) to wind.
static func set_weather(intensity: float, direction: Vector2 = Vector2(1.0, 0.3)) -> void:
	var t := clampf(intensity, 0.0, 1.0)
	set_wind_enabled(true)
	set_wind(lerpf(0.4, 2.6, t), direction, lerpf(0.8, 1.9, t))


## The shared palm material, e.g. for MultiMeshInstance3D.material_override.
static func get_material() -> ShaderMaterial:
	return PALM_MATERIAL
