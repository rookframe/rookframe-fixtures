# Rookframe fixture Packages

Public author projects and immutable releases for Rookframe application development and device QA. Install with **Install from URL** using a public Manifest below; an invited World supplies that URL for automatic acquisition. Downloads require no account or token. Catalogue listing is optional.

| Package | Public Manifest |
| --- | --- |
| Workshop System 0.15.0 | [Manifest](https://github.com/rookframe/rookframe-fixtures/releases/download/v0.15.0/Workshop-System-0.15.0.json) |
| Builder Reference Finishes 0.1.1 | [Manifest](https://github.com/rookframe/rookframe-fixtures/releases/download/v0.1.1/Builder-Reference-Finishes-0.1.1.json) |
| Tabletop Pieces 0.9.4 | [Manifest](https://github.com/rookframe/rookframe-fixtures/releases/download/v0.9.4/Tabletop-Pieces-0.9.4.json) |

Workshop System provides Hero Actors, Actor sheets and a separate Actor browser, journal System Records, Player Actor Access controls, and Rules actions using accepted shared Targeting. Tabletop Pieces provides the Bevy Amber Warden and Goblin Raider Miniatures, plus Crate, Stone and Wood visual content. Select these two releases together for the remote-action QA World.

## Author projects

`workshop-system/` and `tabletop-pieces/` are ordinary Godot author projects. Each includes the gd-plug bootstrap and license, an exact SDK dependency (Workshop 0.15.0; Tabletop Pieces 0.10.1), a separately pinned public UI Kit, and a committed authoring lock. From either project directory, install the dependencies:

```sh
Godot --headless --path . --script plug.gd install
python3 addons/rookframe_sdk/rookframe_authoring.py check --project . --godot /path/to/Godot
python3 addons/rookframe_sdk/rookframe_authoring.py build --project . --godot /path/to/Godot --output build/package.rookpackage
```

Publish the exact checked Manifest and archive before using a new version in application QA. Use Manifest-based acquisition; local archive imports are prohibited for QA. Releases retain their exact bytes and tags. Both projects produce one shared artifact with desktop, tablet and phone resources.

## Existing fixture release

The Rookframe Fixture System and Fixture Essentials 1.0.7 release remains available unchanged. It added public acquisition links and contains desktop, Android, iOS and dedicated-headless profiles built with Godot 4.7.2. Existing older release assets are unchanged.

Workshop 0.15.0 requests a human attack Throw through the native Dice Tray with named attack and damage dice. Its durable waiting record survives reconnects, and the Extension recovers the terminal result before applying its DR 12 rule and explicitly publishing the interpreted HIT, MISS, or cancellation report. Actor-creation and journal drafts also survive reconnects without implicit submission.

`builder-reference-finishes/` is the data-only Godot author project for the five original Bevy architectural models. It uses SDK 0.12.1, preserves the original GLBs and Blender sources, and publishes ordinary typed Wall Style and Surface Finish Content. Both Surface Finishes support independent Floor and Ceiling selection.

Tabletop Pieces 0.9.2 adds the wall-height bookshelf Prop: 3,620 triangles, one PBR material, 1.5 × 2.8 × 0.5 m, with an ordinary authored collision shape.

Tabletop Pieces 0.9.4 removes the unapproved Lattice Lamp and Sprite Banner QA Props and their shared texture. The approved bookshelf, existing content, and Crate collision correction remain. New Props require explicit user approval of the specific design before implementation, publication, or placement.
