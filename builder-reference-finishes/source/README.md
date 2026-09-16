# Builder Reference Finishes

This content-only fixture contains three Wall Styles and two Surface Finishes
authored for the first Builder implementation. Editable Blender sources and
their redistributable CC0 PBR maps are under `authoring/`; full source and
licence provenance is recorded in
[`THIRD_PARTY_ASSETS.md`](THIRD_PARTY_ASSETS.md).

This content-only Package is the launch fixture for ADR 0019 and ADR 0020's
architectural appearance implementation.

| Content ID | Kind | Visual direction |
| --- | --- | --- |
| `timber-plaster-wall` | Wall Style | Timber frame, warm plaster, diagonal bracing |
| `rough-stone-wall` | Wall Style | Dark irregular masonry and cap course |
| `ornate-stone-panel-wall` | Wall Style | Pale veined stone, nested moulding, pilasters, skirting, cornice |
| `dark-stone-tiles` | Surface Finish | Worn square charcoal flagstones |
| `oak-planks` | Surface Finish | Staggered warm oak boards |

Every Surface Finish is available in both the Floor and Ceiling selectors. A
Region may select the same finish for both slots or choose different finishes.
Every Wall Style module is authored exactly one VTT square wide and is consumed
at its package-authored scale.

The authoritative Package payload is under `content/`. Editable Blender
sources, checked-in CC0 material maps, and the deterministic scene generator
are under `authoring/`; none of that authoring material is included in the
content-only Package archive.

Validate the completed asset payload from this directory with:

```sh
node authoring/validate_assets.mjs
```

The validator checks all five descriptors and editable `.blend` files, ten
declared static artifacts, PNG metadata, the embedded binary glTF profile,
semantic hierarchy, axes, UVs, PBR materials, and Wall Style role-module fit.

## Package boundary

This fixture follows the live contract in
`docs/product/architectural-appearance-content.md`. The Package CLI puts each
GLB and preview at its matching `content/...` archive path, validates the
descriptor against the manifest, and keeps this Package content-only.
