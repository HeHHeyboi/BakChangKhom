class_name CleanTool extends Resource

enum Fit {
	FORBIDDEN,
	LIMITED,
	IDEAL,
} # ❌ / 🟡 / ✅

@export var id: StringName # "eraser_white"
@export var display_name: String # "ยางลบสีขาว"
@export var icon: Texture2D
@export_range(0, 5) var hardness: int = 0
@export var has_moisture: bool = false
@export var esd_risk: bool = false
@export var leaves_residue: bool = false
@export var reaches_narrow: bool = false
@export var fit_per_step: Dictionary[int, Fit] = { } # CleanStep -> Fit
@export_multiline var line_ideal: String = ""
@export_multiline var line_limited: String = ""
@export_multiline var line_forbidden: String = ""
