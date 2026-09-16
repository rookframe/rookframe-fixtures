# Third-Party Assets

The binary PBR maps under `authoring/textures/` are redistributed under
[CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/).
Attribution is not required by CC0; this inventory is retained so every map is
traceable and replaceable.

The Dungeon Alchemist screenshots supplied during authoring were visual
references only. They are not copied into this Package.

## Poly Haven

Poly Haven publishes its assets as CC0. See the
[Poly Haven licence](https://polyhaven.com/license).

| Local map prefix | Source | Author(s) | Maps used |
| --- | --- | --- | --- |
| `stone-masonry-*` | [Castle Wall Variation](https://polyhaven.com/a/castle_wall_varriation) | Rob Tuytel | Diffuse, OpenGL normal, roughness |
| `top-course-stone-*` | [Rock 01](https://polyhaven.com/a/rock_01) | Rob Tuytel | Diffuse, OpenGL normal, roughness |
| `warm-plaster-*` | [Beige Wall 001](https://polyhaven.com/a/beige_wall_001) | Dimitrios Savva, Rico Cilliers | Diffuse, OpenGL normal, roughness |

## ambientCG

ambientCG publishes its assets as CC0. See the
[ambientCG licence](https://docs.ambientcg.com/license/).

| Local map prefix | Source | Maps used |
| --- | --- | --- |
| `rough-timber-*` | [Wood 076](https://ambientcg.com/a/Wood076) | Color, OpenGL normal, roughness |
| `pale-marble-*` | [Marble 012](https://ambientcg.com/a/Marble012) | Color, OpenGL normal, roughness |
| `dark-stone-tiles-*` | [Tiles 085](https://ambientcg.com/view?id=Tiles085) | Color, OpenGL normal, roughness |
| `oak-planks-*` | [Planks 023 A](https://ambientcg.com/view?id=Planks023A) | Color, OpenGL normal, roughness |

## Use inside the fixture

- The timber-and-plaster wall uses `warm-plaster` and `rough-timber`.
- The rough-stone wall uses small irregular `stone-masonry` for its body and
  distinct large dressed `top-course-stone` for its thicker final course.
- The ornate panel wall uses `pale-marble`.
- The two Surface Finishes use `dark-stone-tiles` and `oak-planks`.

Only texture maps are incorporated. No third-party mesh, preview render, or
source `.blend` is included.
