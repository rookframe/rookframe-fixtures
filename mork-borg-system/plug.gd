extends "res://addons/gd-plug/plug.gd"


func request_quit(exit_code := -1) -> bool:
	return super.request_quit(0 if exit_code == -1 else exit_code)


func _plugging() -> void:
	plug("rookframe/rookframe-sdk", {"tag": "v0.16.0", "include": ["addons/rookframe_sdk"]})
	plug("rookframe/rookframe-ui-kit", {"commit": "9de97beeede7f9d803e6ea0abef67730cdc84692", "include": ["rookframe/ui"]})
