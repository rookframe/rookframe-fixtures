extends SceneTree

## Trusted author-only import of the preserved Bevy GLBs. Never shipped in a Package.
func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rookframe.json"))
	for entry: Dictionary in manifest.content[0].entries:
		var output := "res://rookframe/packages/%s/content/%s/" % [manifest.id, entry.id]
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var source := "res://source/content/%s/appearance.glb" % entry.id
		var result := document.append_from_file(source, state, GLTFDocument.IMPORT_FLAG_GENERATE_TANGENT_ARRAYS)
		if result != OK:
			fail("GLB import failed: %s (%s)" % [source, result])
			return
		# Keep original material properties; replace only embedded image handles
		# with the same byte-for-byte extracted images in the Package namespace.
		var images := state.get_images()
		for material in state.get_materials():
			for slot in range(BaseMaterial3D.TEXTURE_MAX):
				var texture: Texture2D = material.get_texture(slot)
				if texture == null:
					continue
				var index := images.find(texture)
				if index < 0:
					fail("Importer produced an unmapped texture for %s" % entry.id)
					return
				var path := output + "texture-%s" % index
				path += ".png" if FileAccess.file_exists(path + ".png") else ".jpg"
				material.set_texture(slot, load(path))
		var scene := document.generate_scene(state)
		if scene == null:
			fail("GLB scene generation failed: " + source)
			return
		scene.set_meta("content_kind", entry.type)
		scene.set_meta("authored_unit_span", 1.0)
		scene.set_meta("source_commit", "1230e73777ee0fa2f4e17ec8c804e0c4061465de")
		scene.set_meta("source_sha256", FileAccess.get_sha256(source))
		if entry.type == "surface_finish":
			scene.set_meta("supports_floor", true)
			scene.set_meta("supports_ceiling", true)
		var packed := PackedScene.new()
		result = packed.pack(scene)
		if result == OK:
			result = ResourceSaver.save(packed, output + "appearance.tscn")
		scene.free()
		if result != OK:
			fail("Native scene save failed: %s (%s)" % [entry.id, result])
			return
		print("Converted ", entry.id)
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
