# Builder Reference Finishes — Godot authoring project

One data-only optional Package containing the original Bevy Builder models:

| Content ID | Display name | Type | Uses |
| --- | --- | --- | --- |
| `timber-plaster-wall` | Timber and Plaster Wall | Wall Style | Wall appearance |
| `rough-stone-wall` | Rough Stone Wall | Wall Style | Wall appearance |
| `ornate-stone-panel-wall` | Ornate Stone Panel Wall | Wall Style | Wall appearance |
| `dark-stone-tiles` | Dark Stone Tiles | Surface Finish | Floor and Ceiling independently |
| `oak-planks` | Oak Planks | Surface Finish | Floor and Ceiling independently |

Package ID: `dd07cd6c-d4f5-40e1-b3f2-44d2d59c7f7f`, version `0.1.0`.
The Bevy UUID was not a current-contract UUIDv4; it is retained as provenance,
not used as a Godot Package identity. All five original Package-local Content
IDs remain unchanged. There is no Implementation, Presentation, executable
facade, Settings contribution, System restriction or dependency on another Package.

## Open, check, and build

Use the stock pinned Godot **4.7.2 Mono** and Python 3.10+ / .NET 8.
The included gd-plug bootstrap installs the exact public SDK **0.12.1** and
independently pinned UI Kit. From this project directory:

```sh
godot --headless --path . --script plug.gd install
godot --editor --path .
```

In Godot, use **Project → Tools → Rookframe: Check Package**, then
**Rookframe: Build Package**. The enabled stock EditorPlugin invokes the existing
SDK checker and builder. The output uses `build/<package-id>-0.1.0-<unique-output-id>.rookpackage`;
an existing output is never overwritten. Publication uses the download filename
recorded in the Manifest. Every deliberate rebuild receives a new immutable Build ID.
Equivalent supported CLI actions are:

```sh
python3 addons/rookframe_sdk/rookframe_authoring.py check --project .
python3 addons/rookframe_sdk/rookframe_authoring.py build --project .
```

This project adds no Package builder. The SDK prepares and admits the complete
resource closure, relocates it to a fresh build namespace, and exports one shared
PCK with the existing texture alternatives. The SDK and UI Kit, original GLBs,
Blender sources and conversion tools remain author inputs outside the Package
namespace. Only native scenes, their texture dependencies and previews ship.

## Authored Content contract

Each Manifest payload is an ordinary `PackedScene` (`appearance.tscn`) with
native `Node3D`, `MeshInstance3D`, `ArrayMesh`, and `StandardMaterial3D` resources.
The original glTF hierarchy and local transforms are retained below the imported
root: `WallStyle/Common/Surface`, `Detail` and `Top` where authored, or
`SurfaceFinish/Surface`. The module spans one World unit; no corrective scaling
or flat-material replacement is applied. UVs, vertex normals/tangents, albedo,
normal and metallic/roughness maps, texture channels, double-sided culling and
normal-map strength are preserved. Preview PNGs and extracted embedded texture
bytes are copied exactly from the pinned source.

Root metadata is pure Godot data: `content_kind` matches the Manifest's typed
declaration, `authored_unit_span` is `1.0`, and `source_commit` / `source_sha256`
identify the original GLB. Both Surface Finish roots explicitly declare
`supports_floor = true` and `supports_ceiling = true`. A Region stores independent
Content References for its Floor and Ceiling even when both select one finish.
These are appearance samples and decorative models. They contain no collision,
Region state, generated structural shell or opening behavior; subsequent Room
slices apply the installed Content through checked loading and derive structural
collision independently. Decorative presentation must preserve Portal openings.

## Reproduce the source conversion

`source/provenance.json` pins the Bevy repository, commit and hashes of all five
GLBs, descriptors and original previews. The unchanged Blender sources, map
inventory and original generator are retained under `source/authoring/` for editing;
see [THIRD_PARTY_ASSETS.md](THIRD_PARTY_ASSETS.md) for CC0 texture attribution.
The original legacy descriptors are historical inputs, not runtime definitions.

To regenerate the native authoring scenes from the preserved GLBs:

```sh
python3 extract_images.py
godot --headless --path . --editor --import
godot --headless --path . --script convert_assets.gd
```

The extractor verifies source hashes and copies embedded JPEG/PNG bytes.
The converter uses stock `GLTFDocument`, `PackedScene.pack` and `ResourceSaver`;
it preserves materials and redirects only texture handles to the extracted
Package-local resources. Regeneration may assign fresh editor resource IDs;
the normal SDK build supplies the immutable runtime identity. Regenerating
source never replaces a published archive.

## Published installation

Public [0.1.0 Manifest](https://github.com/rookframe/rookframe-fixtures/releases/download/builder-reference-finishes-v0.1.0/Builder-Reference-Finishes-0.1.0.json).

In stopped Manager, open Installed Packages → Install Package, paste this public
HTTPS Manifest link, and choose Install from link. Include Builder Reference
Finishes in the World's Packages with one published System Extension. Joining
Participants acquire the exact release through ordinary World preparation.
Do not import a local archive, copy a Package store, or bundle these models into
the application for QA. Catalogue listing is optional.
