"""Extract the original embedded image bytes; no rendering or Package building."""

import hashlib
import json
from pathlib import Path
import shutil
import struct

project = Path(__file__).resolve().parent
manifest = json.loads((project / "rookframe.json").read_text())
provenance = json.loads((project / "source/provenance.json").read_text())
for source in provenance["files"]:
    path = project / source["path"]
    if hashlib.sha256(path.read_bytes()).hexdigest() != source["sha256"]:
        raise ValueError(f"Preserved source changed: {path}")

for entry in manifest["content"][0]["entries"]:
    source = project / "source/content" / entry["id"]
    output = project / "rookframe/packages" / manifest["id"] / "content" / entry["id"]
    output.mkdir(parents=True, exist_ok=True)
    data = (source / "appearance.glb").read_bytes()
    json_size = struct.unpack_from("<I", data, 12)[0]
    gltf = json.loads(data[20 : 20 + json_size])
    binary = data[28 + json_size :]
    for index, image in enumerate(gltf["images"]):
        view = gltf["bufferViews"][image["bufferView"]]
        start = view.get("byteOffset", 0)
        extension = {"image/png": "png", "image/jpeg": "jpg"}[image["mimeType"]]
        (output / f"texture-{index}.{extension}").write_bytes(
            binary[start : start + view["byteLength"]]
        )
    shutil.copyfile(source / "preview.png", output / "preview.png")
