# Builder Reference Finishes Authoring Sources

The five `.blend` files in `blend/` are optional editable sources. Their
exported GLBs, previews, and `content.json` files under `content/` are the
authoritative Package payloads.

The source scenes use ordinary Blender Empties, mesh objects, Principled BSDF
materials, linked images from `textures/`, and Blender's built-in binary glTF
exporter. Keep the `blend/` and `textures/` directories together when moving
the authoring sources. They do not require a Rookframe plug-in or custom
exporter.

The visual references inform these compact, low-poly interpretations:

- `timber-plaster-wall`: warm plaster, exposed dark oak framing, and diagonal
  bracing;
- `rough-stone-wall`: dark irregular masonry with a projecting cap course;
- `ornate-stone-panel-wall`: a pale veined stone panel with nested moulding,
  skirting, cornice, and boundary pilasters;
- `dark-stone-tiles`: worn square charcoal flagstones; and
- `oak-planks`: staggered warm oak boards.

Every Wall Style authors one complete horizontal module at exactly one VTT
square. Rookframe places these models at their authored scale; the package does
not rely on runtime correction. Small surface relief is represented by PBR
maps, while timber framing and architectural moulding remain geometry because
they change the visible profile.

The PBR maps are checked-in CC0 assets from Poly Haven and ambientCG. Their
exact sources, authors, and licences are recorded in
[`../THIRD_PARTY_ASSETS.md`](../THIRD_PARTY_ASSETS.md). The original Dungeon
Alchemist screenshots are not included.

Both Surface Finishes are valid for Floor and Ceiling because every
`surface_finish` uses the same shared selector contract.

From this Package directory, run `node authoring/validate_assets.mjs` to verify
the descriptors, Package declarations, PNG previews, embedded GLB resources,
core PBR profile, semantic hierarchy, Surface axes/UVs, and role-module fit.
