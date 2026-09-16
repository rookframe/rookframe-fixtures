"""Generate the editable Blender sources and exported package assets.

This is an optional reproducibility helper. It uses only Blender's Python API
and built-in binary glTF exporter; the saved .blend files remain normally
editable without this script.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


PACKAGE_ROOT = Path(__file__).resolve().parents[1]
CONTENT_ROOT = PACKAGE_ROOT / "content"
AUTHORING_ROOT = PACKAGE_ROOT / "authoring"
TEXTURE_ROOT = AUTHORING_ROOT / "textures"
BLEND_ROOT = AUTHORING_ROOT / "blend"
PBR_TEXTURES = {
    "stone-masonry": {
        "base_color": "stone-masonry-basecolor.jpg",
        "normal": "stone-masonry-normal.jpg",
        "roughness": "stone-masonry-roughness.jpg",
    },
    "top-course-stone": {
        "base_color": "top-course-stone-basecolor.jpg",
        "normal": "top-course-stone-normal.jpg",
        "roughness": "top-course-stone-roughness.jpg",
    },
    "rough-timber": {
        "base_color": "rough-timber-basecolor.jpg",
        "normal": "rough-timber-normal.jpg",
        "roughness": "rough-timber-roughness.jpg",
    },
    "warm-plaster": {
        "base_color": "warm-plaster-basecolor.jpg",
        "normal": "warm-plaster-normal.jpg",
        "roughness": "warm-plaster-roughness.jpg",
    },
    "pale-marble": {
        "base_color": "pale-marble-basecolor.jpg",
        "normal": "pale-marble-normal.jpg",
        "roughness": "pale-marble-roughness.jpg",
    },
    "dark-stone-tiles": {
        "base_color": "dark-stone-tiles-basecolor.jpg",
        "normal": "dark-stone-tiles-normal.jpg",
        "roughness": "dark-stone-tiles-roughness.jpg",
    },
    "oak-planks": {
        "base_color": "oak-planks-basecolor.jpg",
        "normal": "oak-planks-normal.jpg",
        "roughness": "oak-planks-roughness.jpg",
    },
}
WALL_MODULE_WIDTH = 1.0


def generate_textures() -> list[str]:
    """Verify the checked-in CC0 maps used by the reproducible build."""
    required = [
        TEXTURE_ROOT / filename
        for maps in PBR_TEXTURES.values()
        for filename in maps.values()
    ]
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise FileNotFoundError("missing CC0 PBR maps: " + ", ".join(missing))
    return [str(path) for path in required]


def _clear_scene() -> None:
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for collection in list(bpy.data.collections):
        bpy.data.collections.remove(collection)
    for datablocks in (
        bpy.data.meshes,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
        bpy.data.worlds,
    ):
        for block in list(datablocks):
            datablocks.remove(block)
    for image in list(bpy.data.images):
        if image.name not in {"Render Result", "Viewer Node"}:
            bpy.data.images.remove(image)


def _configure_scene() -> None:
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = False
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.view_settings.exposure = -0.15
    scene.world = bpy.data.worlds.new("PreviewWorld")
    scene.world.use_nodes = True
    background = scene.world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.0025, 0.003, 0.0035, 1.0)
    background.inputs["Strength"].default_value = 0.12


def _asset_collection(name: str) -> bpy.types.Collection:
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    return collection


def _link_object(obj: bpy.types.Object, collection: bpy.types.Collection) -> None:
    for existing in list(obj.users_collection):
        existing.objects.unlink(obj)
    collection.objects.link(obj)


def _empty(
    name: str,
    collection: bpy.types.Collection,
    parent: bpy.types.Object | None = None,
) -> bpy.types.Object:
    obj = bpy.data.objects.new(name, None)
    collection.objects.link(obj)
    obj.parent = parent
    obj.empty_display_type = "PLAIN_AXES"
    return obj


def _mesh_object(
    name: str,
    vertices: list[tuple[float, float, float]],
    faces: list[tuple[int, ...]],
    uvs: list[tuple[float, float]],
    material: bpy.types.Material,
    collection: bpy.types.Collection,
    parent: bpy.types.Object | None = None,
) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(f"{name}Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    uv_layer = mesh.uv_layers.new(name="UVMap")
    for polygon in mesh.polygons:
        for local_index, loop_index in enumerate(polygon.loop_indices):
            uv_layer.data[loop_index].uv = uvs[local_index]
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.parent = parent
    obj.data.materials.append(material)
    return obj


def _wall_surface(
    width: float,
    height: float,
    material: bpy.types.Material,
    collection: bpy.types.Collection,
    parent: bpy.types.Object,
    *,
    name: str = "Surface",
    uv_height: float = 1.0,
) -> bpy.types.Object:
    half = width * 0.5
    return _mesh_object(
        name,
        [(-half, 0.0, 0.0), (half, 0.0, 0.0), (half, 0.0, height), (-half, 0.0, height)],
        [(0, 1, 2, 3)],
        [(0.0, 0.0), (1.0, 0.0), (1.0, uv_height), (0.0, uv_height)],
        material,
        collection,
        parent,
    )


def _floor_surface(
    width: float,
    depth: float,
    material: bpy.types.Material,
    collection: bpy.types.Collection,
    parent: bpy.types.Object,
) -> bpy.types.Object:
    half_width = width * 0.5
    half_depth = depth * 0.5
    return _mesh_object(
        "Surface",
        [
            (-half_width, -half_depth, 0.0),
            (half_width, -half_depth, 0.0),
            (half_width, half_depth, 0.0),
            (-half_width, half_depth, 0.0),
        ],
        [(0, 1, 2, 3)],
        [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)],
        material,
        collection,
        parent,
    )


def _texture_image_node(
    material: bpy.types.Material,
    name: str,
    path: Path,
    *,
    colorspace: str,
) -> bpy.types.Node:
    image = bpy.data.images.load(str(path), check_existing=True)
    image.colorspace_settings.name = colorspace
    node = material.node_tree.nodes.new("ShaderNodeTexImage")
    node.name = name
    node.image = image
    node.extension = "REPEAT"
    return node


def _texture_material(
    name: str,
    texture_name: str,
    *,
    normal_strength: float = 1.0,
    fallback_roughness: float = 0.75,
    base_color_tint: tuple[float, float, float, float] | None = None,
    base_color_saturation: float = 1.0,
    base_color_value: float = 1.0,
) -> bpy.types.Material:
    maps = PBR_TEXTURES[texture_name]
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = fallback_roughness
    bsdf.inputs["Alpha"].default_value = 1.0

    base_node = _texture_image_node(
        material,
        f"{name} Base Color",
        TEXTURE_ROOT / maps["base_color"],
        colorspace="sRGB",
    )
    color_output = base_node.outputs["Color"]
    if base_color_tint is not None:
        tint = nodes.new("ShaderNodeMixRGB")
        tint.blend_type = "MULTIPLY"
        tint.inputs[0].default_value = 1.0
        tint.inputs[2].default_value = base_color_tint
        links.new(base_node.outputs["Color"], tint.inputs[1])
        color_output = tint.outputs["Color"]
    if base_color_saturation != 1.0 or base_color_value != 1.0:
        grading = nodes.new("ShaderNodeHueSaturation")
        grading.inputs["Saturation"].default_value = base_color_saturation
        grading.inputs["Value"].default_value = base_color_value
        links.new(color_output, grading.inputs["Color"])
        color_output = grading.outputs["Color"]
    links.new(color_output, bsdf.inputs["Base Color"])

    if "normal" in maps:
        normal_texture = _texture_image_node(
            material,
            f"{name} Normal",
            TEXTURE_ROOT / maps["normal"],
            colorspace="Non-Color",
        )
        normal_map = nodes.new("ShaderNodeNormalMap")
        normal_map.inputs["Strength"].default_value = normal_strength
        links.new(normal_texture.outputs["Color"], normal_map.inputs["Color"])
        links.new(normal_map.outputs["Normal"], bsdf.inputs["Normal"])

    if "roughness" in maps:
        roughness_texture = _texture_image_node(
            material,
            f"{name} Roughness",
            TEXTURE_ROOT / maps["roughness"],
            colorspace="Non-Color",
        )
        links.new(roughness_texture.outputs["Color"], bsdf.inputs["Roughness"])
    return material


def _set_box_uv_scale(
    obj: bpy.types.Object,
    scale_u: float,
    scale_v: float,
    *,
    offset_u: float = 0.0,
    offset_v: float = 0.0,
) -> None:
    uv_layer = obj.data.uv_layers.active
    for loop in uv_layer.data:
        loop.uv.x = loop.uv.x * scale_u + offset_u
        loop.uv.y = loop.uv.y * scale_v + offset_v


def _roughen_box_edges(
    obj: bpy.types.Object,
    *,
    amount: float,
    seed: int,
) -> None:
    """Add deterministic dressed-stone irregularity without dense geometry."""
    for vertex in obj.data.vertices:
        co = vertex.co
        signature = math.sin(
            (vertex.index + 1) * (12.9898 + seed * 0.173)
            + co.x * 19.19
            + co.y * 7.31
            + co.z * 23.71
        )
        co.x += amount * signature
        co.y += amount * 0.45 * math.sin(signature * 5.17 + seed)
        co.z += amount * 0.70 * math.sin(signature * 3.11 - seed)


def _flat_material(
    name: str,
    color: tuple[float, float, float, float],
    roughness: float,
) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Alpha"].default_value = 1.0
    material.diffuse_color = color
    return material


def _box(
    name: str,
    dimensions: tuple[float, float, float],
    location: tuple[float, float, float],
    material: bpy.types.Material,
    collection: bpy.types.Collection,
    parent: bpy.types.Object,
    *,
    rotation_y: float = 0.0,
    bevel: float = 0.008,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, calc_uvs=True, location=location)
    obj = bpy.context.object
    obj.name = name
    _link_object(obj, collection)
    obj.parent = parent
    obj.dimensions = dimensions
    obj.rotation_euler.y = rotation_y
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if bevel > 0.0:
        modifier = obj.modifiers.new("SoftenedEdges", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.limit_method = "ANGLE"
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.data.materials.append(material)
    return obj


def _beam_between(
    name: str,
    start: tuple[float, float],
    end: tuple[float, float],
    thickness: float,
    depth: float,
    material: bpy.types.Material,
    collection: bpy.types.Collection,
    parent: bpy.types.Object,
) -> bpy.types.Object:
    dx = end[0] - start[0]
    dz = end[1] - start[1]
    length = math.hypot(dx, dz)
    return _box(
        name,
        (length, depth, thickness),
        ((start[0] + end[0]) * 0.5, -(depth * 0.5 + 0.012), (start[1] + end[1]) * 0.5),
        material,
        collection,
        parent,
        rotation_y=-math.atan2(dz, dx),
        bevel=min(0.018, thickness * 0.15),
    )


def _look_at(obj: bpy.types.Object, target: tuple[float, float, float]) -> None:
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def _preview_rig(
    target: tuple[float, float, float],
    camera_location: tuple[float, float, float],
) -> tuple[bpy.types.Collection, bpy.types.Object]:
    collection = bpy.data.collections.new("PreviewRig")
    bpy.context.scene.collection.children.link(collection)

    camera_data = bpy.data.cameras.new("PreviewCamera")
    camera = bpy.data.objects.new("PreviewCamera", camera_data)
    collection.objects.link(camera)
    camera.location = camera_location
    camera.data.lens = 62.0
    _look_at(camera, target)
    bpy.context.scene.camera = camera

    for name, location, energy, size, color in (
        ("Key", (-3.2, -4.2, 5.5), 820.0, 4.5, (1.0, 0.91, 0.80)),
        ("Fill", (4.0, -2.5, 3.2), 210.0, 4.0, (0.72, 0.82, 1.0)),
        ("Rim", (0.5, 3.2, 4.0), 340.0, 3.0, (0.78, 0.86, 1.0)),
    ):
        light_data = bpy.data.lights.new(name, "AREA")
        light_data.energy = energy
        light_data.shape = "DISK"
        light_data.size = size
        light_data.color = color
        light = bpy.data.objects.new(name, light_data)
        collection.objects.link(light)
        light.location = location
        _look_at(light, target)
    return collection, camera


def _remove_collection(collection: bpy.types.Collection) -> None:
    for obj in list(collection.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(collection)


def _render_wall_preview(
    asset_id: str,
    width: float,
    wall_height: float,
    repeat_height: float,
    surface_material: bpy.types.Material,
    semantic_surface: bpy.types.Object,
    asset_collection: bpy.types.Collection,
    *,
    top_role: bpy.types.Object | None = None,
    top_offset: float = 0.0,
    preview_exposure: float | None = None,
    wall_depth: float | None = None,
    camera_location: tuple[float, float, float] | None = None,
) -> None:
    rig, _ = _preview_rig(
        (0.0, 0.0, wall_height * 0.50),
        camera_location or (width * 1.65, -4.7, wall_height * 1.05),
    )
    preview_surface = _wall_surface(
        width,
        wall_height,
        surface_material,
        rig,
        parent=None,
        name="PreviewGeneratedWall",
        uv_height=wall_height / repeat_height,
    )
    preview_surface.location.y = (
        -(wall_depth * 0.5 + 0.001) if wall_depth is not None else 0.0
    )
    preview_surface.rotation_euler.z = math.pi
    semantic_surface.hide_render = True

    # Preview-only structural depth. Wall Style files still contribute a face
    # sample; Rookframe owns the continuous structural wall core at runtime.
    if wall_depth is not None:
        body = _box(
            "PreviewStructuralBody",
            (width, wall_depth, wall_height),
            (0.0, 0.0, wall_height * 0.5),
            surface_material,
            rig,
            parent=None,
            bevel=0.0,
        )
        body.data.materials.clear()
        body.data.materials.append(
            _flat_material("PreviewStructuralStone", (0.13, 0.14, 0.13, 1.0), 0.94)
        )

    ground_material = _flat_material("PreviewGround", (0.003, 0.004, 0.0045, 1.0), 0.96)
    bpy.ops.mesh.primitive_plane_add(size=18.0, location=(0.0, 0.0, -0.012))
    ground = bpy.context.object
    ground.name = "PreviewGround"
    _link_object(ground, rig)
    ground.data.materials.append(ground_material)

    if top_role is not None:
        top_role.location.z = top_offset

    scene = bpy.context.scene
    normal_exposure = scene.view_settings.exposure
    if preview_exposure is not None:
        scene.view_settings.exposure = preview_exposure
    scene.render.filepath = str(CONTENT_ROOT / asset_id / "preview.png")
    bpy.ops.render.render(write_still=True)
    scene.view_settings.exposure = normal_exposure

    if top_role is not None:
        top_role.location.z = 0.0
    semantic_surface.hide_render = False
    _remove_collection(rig)


def _render_surface_preview(asset_id: str, width: float, depth: float) -> None:
    target = (0.0, 0.0, 0.0)
    span = max(width, depth)
    rig, _ = _preview_rig(target, (span * 1.45, -span * 1.65, span * 1.45))
    scene = bpy.context.scene
    normal_exposure = scene.view_settings.exposure
    scene.view_settings.exposure = -0.25
    scene.render.filepath = str(CONTENT_ROOT / asset_id / "preview.png")
    bpy.ops.render.render(write_still=True)
    scene.view_settings.exposure = normal_exposure
    _remove_collection(rig)


def _descendants(root: bpy.types.Object) -> list[bpy.types.Object]:
    values = [root]
    for child in root.children:
        values.extend(_descendants(child))
    return values


def _export_and_save(asset_id: str, root: bpy.types.Object) -> dict[str, str]:
    content_directory = CONTENT_ROOT / asset_id
    content_directory.mkdir(parents=True, exist_ok=True)
    BLEND_ROOT.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in _descendants(root):
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root

    glb_path = content_directory / "appearance.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(glb_path),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_texcoords=True,
        export_normals=True,
        export_tangents=False,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
        export_animations=False,
        export_skins=False,
        export_morph=False,
        export_apply=False,
        export_extras=True,
        export_image_format="AUTO",
        export_keep_originals=False,
    )
    blend_path = BLEND_ROOT / f"{asset_id}.blend"
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path), check_existing=False)
    return {"asset": asset_id, "glb": str(glb_path), "blend": str(blend_path)}


def build_timber_plaster_wall() -> dict[str, str]:
    _clear_scene()
    _configure_scene()
    collection = _asset_collection("TimberPlasterWall")
    plaster = _texture_material("Aged Warm Plaster", "warm-plaster", normal_strength=0.45)
    timber = _texture_material("Weathered Oak Timber", "rough-timber", normal_strength=0.85)
    x_scale = WALL_MODULE_WIDTH / 2.0

    root = _empty("WallStyle", collection)
    common = _empty("Common", collection, root)
    surface = _wall_surface(WALL_MODULE_WIDTH, 1.0, plaster, collection, common)
    detail = _empty("Detail", collection, common)
    top = _empty("Top", collection, common)

    for timber_part in (
        _box("LeftPost", (0.135 * x_scale, 0.135, 2.8), (-0.925 * x_scale, -0.076, 1.4), timber, collection, detail),
        _box("RightPost", (0.135 * x_scale, 0.135, 2.8), (0.925 * x_scale, -0.076, 1.4), timber, collection, detail),
        _box("LowerRail", (1.86 * x_scale, 0.125, 0.13), (0.0, -0.070, 0.18), timber, collection, detail),
        _box("MiddleRail", (1.86 * x_scale, 0.125, 0.13), (0.0, -0.070, 1.28), timber, collection, detail),
        _box("UpperRail", (1.86 * x_scale, 0.125, 0.13), (0.0, -0.070, 2.18), timber, collection, detail),
    ):
        _set_box_uv_scale(timber_part, 0.55, 0.55)
    # Both braces are exact mirrors around x = 0 and meet at the bay's center.
    # Extend the brace centerlines into the horizontal rails. Their cut ends
    # are therefore buried inside the join instead of stopping visibly short.
    brace_outer_z = 2.18
    brace_center_z = 1.28
    brace_outer_x = 0.76 * x_scale
    _beam_between(
        "LeftBrace",
        (-brace_outer_x, brace_outer_z),
        (0.0, brace_center_z),
        0.10,
        0.10,
        timber,
        collection,
        detail,
    )
    _beam_between(
        "RightBrace",
        (0.0, brace_center_z),
        (brace_outer_x, brace_outer_z),
        0.10,
        0.10,
        timber,
        collection,
        detail,
    )

    _box("TimberCap", (1.98 * x_scale, 0.17, 0.17), (0.0, -0.09, 0.085), timber, collection, top, bevel=0.010)
    _render_wall_preview(
        "timber-plaster-wall",
        WALL_MODULE_WIDTH,
        2.8,
        1.0,
        plaster,
        surface,
        collection,
        top_role=top,
        top_offset=2.63,
        preview_exposure=-0.25,
    )
    return _export_and_save("timber-plaster-wall", root)


def build_rough_stone_wall() -> dict[str, str]:
    _clear_scene()
    _configure_scene()
    collection = _asset_collection("RoughStoneWall")
    surface_material = _texture_material(
        "Weathered Coursed Masonry",
        "stone-masonry",
        normal_strength=1.25,
        fallback_roughness=0.9,
        base_color_tint=(0.38, 0.43, 0.41, 1.0),
        base_color_saturation=0.68,
    )
    cap_material = _texture_material(
        "Large Dressed Top-Course Stone",
        "top-course-stone",
        normal_strength=1.35,
        fallback_roughness=0.86,
        base_color_tint=(1.0, 0.88, 0.64, 1.0),
        base_color_saturation=0.72,
        base_color_value=1.95,
    )
    x_scale = WALL_MODULE_WIDTH / 1.5
    root = _empty("WallStyle", collection)
    common = _empty("Common", collection, root)
    surface = _wall_surface(WALL_MODULE_WIDTH, 1.0, surface_material, collection, common)
    top = _empty("Top", collection, common)
    # The body remains a two-triangle tiled face sample. The final course is a
    # genuinely thicker row centered over the engine-owned structural wall,
    # projecting equally from both sides as shown in the supplied side view.
    capstone_widths = tuple(
        width * x_scale for width in (0.294, 0.284, 0.304, 0.284, 0.304)
    )
    capstone_heights = (0.295, 0.285, 0.302, 0.290, 0.298)
    capstone_uv_offsets = (
        (0.03, 0.06),
        (0.29, 0.12),
        (0.54, 0.03),
        (0.14, 0.48),
        (0.42, 0.55),
    )
    structural_wall_depth = 0.15
    capstone_depth = 0.29
    capstone_cursor = -0.75 * x_scale
    for index, (width, height, uv_offset) in enumerate(
        zip(capstone_widths, capstone_heights, capstone_uv_offsets), start=1
    ):
        x = capstone_cursor + width * 0.5
        cap = _box(
            f"Capstone{index:02d}",
            (width, capstone_depth, height),
            (x, 0.0, height * 0.5),
            cap_material,
            collection,
            top,
            bevel=0.020,
        )
        _roughen_box_edges(cap, amount=0.007, seed=index)
        _set_box_uv_scale(
            cap,
            0.30,
            0.30,
            offset_u=uv_offset[0],
            offset_v=uv_offset[1],
        )
        capstone_cursor += width
    _render_wall_preview(
        "rough-stone-wall",
        WALL_MODULE_WIDTH,
        2.8,
        2.8,
        surface_material,
        surface,
        collection,
        top_role=top,
        top_offset=2.80,
        preview_exposure=-0.80,
        wall_depth=structural_wall_depth,
        camera_location=(2.45, -5.2, 3.65),
    )
    return _export_and_save("rough-stone-wall", root)


def build_ornate_stone_panel_wall() -> dict[str, str]:
    _clear_scene()
    _configure_scene()
    collection = _asset_collection("OrnateStonePanelWall")
    surface_material = _texture_material("Aged Pale Marble", "pale-marble", normal_strength=0.35)
    trim_material = _texture_material("Carved Pale Marble", "pale-marble", normal_strength=0.24)
    accent_material = _texture_material("Recessed Pale Marble", "pale-marble", normal_strength=0.20)
    x_scale = WALL_MODULE_WIDTH / 1.6

    root = _empty("WallStyle", collection)
    common = _empty("Common", collection, root)
    surface = _wall_surface(WALL_MODULE_WIDTH, 1.2, surface_material, collection, common)
    detail = _empty("Detail", collection, common)
    base = _empty("Base", collection, common)
    top = _empty("Top", collection, common)

    _box("LeftPilaster", (0.13 * x_scale, 0.13, 2.30), (-0.72 * x_scale, -0.075, 1.40), trim_material, collection, detail, bevel=0.024)
    _box("RightPilaster", (0.13 * x_scale, 0.13, 2.30), (0.72 * x_scale, -0.075, 1.40), trim_material, collection, detail, bevel=0.024)
    _box("PanelShadow", (1.11 * x_scale, 0.035, 1.70), (0.0, -0.025, 1.43), accent_material, collection, detail, bevel=0.018)
    for name, x, height, depth in (
        ("OuterLeft", -0.57, 1.92, 0.105),
        ("OuterRight", 0.57, 1.92, 0.105),
        ("InnerLeft", -0.47, 1.62, 0.085),
        ("InnerRight", 0.47, 1.62, 0.085),
    ):
        _box(name, (0.075 * x_scale, depth, height), (x * x_scale, -(depth * 0.5 + 0.018), 1.43), trim_material, collection, detail, bevel=0.016)
    for name, z, width, depth in (
        ("OuterBottom", 0.47, 1.22, 0.105),
        ("OuterTop", 2.39, 1.22, 0.105),
        ("InnerBottom", 0.62, 1.02, 0.085),
        ("InnerTop", 2.24, 1.02, 0.085),
    ):
        _box(name, (width * x_scale, depth, 0.075), (0.0, -(depth * 0.5 + 0.018), z), trim_material, collection, detail, bevel=0.016)

    _box("SkirtingLower", (1.58 * x_scale, 0.15, 0.10), (0.0, -0.082, 0.05), trim_material, collection, base, bevel=0.015)
    _box("SkirtingMiddle", (1.50 * x_scale, 0.12, 0.09), (0.0, -0.068, 0.145), trim_material, collection, base, bevel=0.014)
    _box("SkirtingUpper", (1.42 * x_scale, 0.09, 0.08), (0.0, -0.052, 0.230), trim_material, collection, base, bevel=0.013)

    _box("CorniceLower", (1.46 * x_scale, 0.11, 0.075), (0.0, -0.060, 0.0375), trim_material, collection, top, bevel=0.014)
    _box("CorniceMiddle", (1.56 * x_scale, 0.16, 0.09), (0.0, -0.085, 0.120), trim_material, collection, top, bevel=0.016)
    _box("CorniceUpper", (1.58 * x_scale, 0.20, 0.10), (0.0, -0.105, 0.215), trim_material, collection, top, bevel=0.018)

    _render_wall_preview(
        "ornate-stone-panel-wall",
        WALL_MODULE_WIDTH,
        2.8,
        1.2,
        surface_material,
        surface,
        collection,
        top_role=top,
        top_offset=2.535,
        preview_exposure=-0.35,
    )
    return _export_and_save("ornate-stone-panel-wall", root)


def _build_surface_finish(
    asset_id: str,
    texture_name: str,
    dimensions: tuple[float, float],
    roughness: float,
    *,
    base_color_tint: tuple[float, float, float, float] | None = None,
) -> dict[str, str]:
    _clear_scene()
    _configure_scene()
    collection = _asset_collection(asset_id)
    material = _texture_material(
        asset_id.replace("-", " ").title(),
        texture_name,
        normal_strength=1.0,
        fallback_roughness=roughness,
        base_color_tint=base_color_tint,
    )
    root = _empty("SurfaceFinish", collection)
    _floor_surface(dimensions[0], dimensions[1], material, collection, root)
    _render_surface_preview(asset_id, dimensions[0], dimensions[1])
    return _export_and_save(asset_id, root)


def build_dark_stone_tiles() -> dict[str, str]:
    return _build_surface_finish(
        "dark-stone-tiles",
        "dark-stone-tiles",
        (1.6, 1.6),
        0.90,
        base_color_tint=(0.28, 0.26, 0.22, 1.0),
    )


def build_oak_planks() -> dict[str, str]:
    return _build_surface_finish(
        "oak-planks",
        "oak-planks",
        (1.6, 1.6),
        0.82,
        base_color_tint=(0.62, 0.40, 0.22, 1.0),
    )


BUILDERS = {
    "timber-plaster-wall": build_timber_plaster_wall,
    "rough-stone-wall": build_rough_stone_wall,
    "ornate-stone-panel-wall": build_ornate_stone_panel_wall,
    "dark-stone-tiles": build_dark_stone_tiles,
    "oak-planks": build_oak_planks,
}


def build_asset(asset_id: str) -> dict[str, str]:
    try:
        builder = BUILDERS[asset_id]
    except KeyError as error:
        raise ValueError(f"unknown asset id: {asset_id}") from error
    return builder()
