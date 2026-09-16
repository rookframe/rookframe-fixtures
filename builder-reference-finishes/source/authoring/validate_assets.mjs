import { readFile, readdir, stat } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";


const authoringRoot = dirname(fileURLToPath(import.meta.url));
const packageRoot = dirname(authoringRoot);
const contentRoot = join(packageRoot, "content");
const semanticRoles = new Set([
  "Surface",
  "Detail",
  "Base",
  "Top",
  "Post",
  "Corner",
  "Join",
  "Terminal",
  "OpeningEdge",
]);


function invariant(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}


async function readJson(path) {
  return JSON.parse(await readFile(path, "utf8"));
}


function exactKeys(value, expected, context) {
  const actual = Object.keys(value).sort();
  const wanted = [...expected].sort();
  invariant(
    JSON.stringify(actual) === JSON.stringify(wanted),
    `${context}: expected fields ${wanted.join(", ")}; found ${actual.join(", ")}`,
  );
}


function identityTransform(node, context) {
  invariant(node.matrix === undefined, `${context}: semantic node has a matrix`);
  invariant(
    node.translation === undefined || node.translation.every((value) => value === 0),
    `${context}: semantic node translation is not identity`,
  );
  invariant(
    node.rotation === undefined
      || JSON.stringify(node.rotation) === JSON.stringify([0, 0, 0, 1]),
    `${context}: semantic node rotation is not identity`,
  );
  invariant(
    node.scale === undefined
      || JSON.stringify(node.scale) === JSON.stringify([1, 1, 1]),
    `${context}: semantic node scale is not identity`,
  );
}


function parseGlb(bytes, context) {
  invariant(bytes.length >= 28, `${context}: truncated GLB`);
  invariant(bytes.readUInt32LE(0) === 0x46546c67, `${context}: invalid GLB magic`);
  invariant(bytes.readUInt32LE(4) === 2, `${context}: GLB is not glTF 2.0`);
  invariant(bytes.readUInt32LE(8) === bytes.length, `${context}: invalid GLB length`);

  let offset = 12;
  let json;
  let binary;
  while (offset < bytes.length) {
    const chunkLength = bytes.readUInt32LE(offset);
    const chunkType = bytes.readUInt32LE(offset + 4);
    const chunk = bytes.subarray(offset + 8, offset + 8 + chunkLength);
    if (chunkType === 0x4e4f534a) {
      invariant(json === undefined, `${context}: duplicate JSON chunk`);
      json = JSON.parse(chunk.toString("utf8").replace(/[\u0000 ]+$/u, ""));
    } else if (chunkType === 0x004e4942) {
      invariant(binary === undefined, `${context}: duplicate BIN chunk`);
      binary = chunk;
    } else {
      throw new Error(`${context}: unsupported GLB chunk ${chunkType}`);
    }
    offset += 8 + chunkLength;
  }
  invariant(json !== undefined && binary !== undefined, `${context}: JSON and BIN chunks required`);
  return { gltf: json, binary };
}


function componentsFor(type) {
  return { SCALAR: 1, VEC2: 2, VEC3: 3, VEC4: 4 }[type];
}


function readFloatAccessor(gltf, binary, accessorIndex, context) {
  const accessor = gltf.accessors[accessorIndex];
  invariant(accessor.componentType === 5126, `${context}: accessor must use float32`);
  invariant(accessor.sparse === undefined, `${context}: sparse accessors are unsupported`);
  const componentCount = componentsFor(accessor.type);
  invariant(componentCount !== undefined, `${context}: unsupported accessor type ${accessor.type}`);
  const view = gltf.bufferViews[accessor.bufferView];
  const stride = view.byteStride ?? componentCount * 4;
  const start = (view.byteOffset ?? 0) + (accessor.byteOffset ?? 0);
  const data = new DataView(binary.buffer, binary.byteOffset, binary.byteLength);
  const values = [];
  for (let row = 0; row < accessor.count; row += 1) {
    const tuple = [];
    for (let component = 0; component < componentCount; component += 1) {
      tuple.push(data.getFloat32(start + row * stride + component * 4, true));
    }
    values.push(tuple);
  }
  return values;
}


function directChildren(gltf, node) {
  return (node.children ?? []).map((index) => ({ index, node: gltf.nodes[index] }));
}


function uniqueChildNames(gltf, node, context) {
  const names = directChildren(gltf, node).map(({ node: child }) => child.name);
  invariant(new Set(names).size === names.length, `${context}: duplicate direct child name`);
  return names;
}


function validatePrimitiveProfile(gltf, context) {
  invariant(gltf.asset?.version === "2.0", `${context}: asset.version must be 2.0`);
  invariant(gltf.scenes?.length === 1, `${context}: exactly one glTF scene is required`);
  invariant((gltf.extensionsUsed ?? []).length === 0, `${context}: glTF extensions are unsupported`);
  invariant((gltf.extensionsRequired ?? []).length === 0, `${context}: required extensions are unsupported`);
  invariant(gltf.cameras === undefined, `${context}: cameras are not package appearance content`);
  invariant(gltf.animations === undefined, `${context}: animation is not supported`);
  invariant((gltf.skins ?? []).length === 0, `${context}: skinning is not supported`);
  invariant(gltf.buffers?.length === 1 && gltf.buffers[0].uri === undefined, `${context}: buffer must be embedded`);
  for (const [index, image] of (gltf.images ?? []).entries()) {
    invariant(image.bufferView !== undefined && image.uri === undefined, `${context}: image ${index} is not embedded`);
    invariant(["image/png", "image/jpeg"].includes(image.mimeType), `${context}: image ${index} codec is unsupported`);
  }
  for (const [index, sampler] of (gltf.samplers ?? []).entries()) {
    invariant(
      (sampler.wrapS ?? 10497) === 10497 && (sampler.wrapT ?? 10497) === 10497,
      `${context}: sampler ${index} does not repeat`,
    );
  }
  for (const [index, material] of (gltf.materials ?? []).entries()) {
    invariant(material.extensions === undefined, `${context}: material ${index} uses an extension`);
    invariant((material.alphaMode ?? "OPAQUE") === "OPAQUE", `${context}: material ${index} is not opaque`);
    invariant(material.pbrMetallicRoughness !== undefined, `${context}: material ${index} is not core PBR`);
  }
  for (const [meshIndex, mesh] of (gltf.meshes ?? []).entries()) {
    for (const [primitiveIndex, primitive] of mesh.primitives.entries()) {
      const primitiveContext = `${context}: mesh ${meshIndex} primitive ${primitiveIndex}`;
      invariant((primitive.mode ?? 4) === 4, `${primitiveContext}: triangles required`);
      invariant(primitive.material !== undefined, `${primitiveContext}: material required`);
      for (const attribute of ["POSITION", "NORMAL", "TEXCOORD_0"]) {
        invariant(primitive.attributes[attribute] !== undefined, `${primitiveContext}: ${attribute} required`);
      }
      invariant(primitive.targets === undefined, `${primitiveContext}: morph targets unsupported`);
    }
  }
}


function validateSurface(gltf, binary, surfaceIndex, kind, context) {
  const surface = gltf.nodes[surfaceIndex];
  identityTransform(surface, `${context}/Surface`);
  invariant(surface.mesh !== undefined, `${context}/Surface: mesh required`);
  invariant((surface.children ?? []).length === 0, `${context}/Surface: descendants unsupported`);
  const mesh = gltf.meshes[surface.mesh];
  invariant(mesh.primitives.length === 1, `${context}/Surface: exactly one primitive required`);
  const primitive = mesh.primitives[0];
  invariant(primitive.material !== undefined, `${context}/Surface: material required`);

  const positions = readFloatAccessor(gltf, binary, primitive.attributes.POSITION, `${context}/Surface/POSITION`);
  const normals = readFloatAccessor(gltf, binary, primitive.attributes.NORMAL, `${context}/Surface/NORMAL`);
  const uvs = readFloatAccessor(gltf, binary, primitive.attributes.TEXCOORD_0, `${context}/Surface/TEXCOORD_0`);
  const bounds = positions[0].map((_, component) => ({
    min: Math.min(...positions.map((value) => value[component])),
    max: Math.max(...positions.map((value) => value[component])),
  }));
  const epsilon = 1.0e-5;
  const flatAxis = kind === "surface_finish" ? 1 : 2;
  const normalAxis = kind === "surface_finish" ? 1 : 2;
  invariant(Math.abs(bounds[flatAxis].min) < epsilon && Math.abs(bounds[flatAxis].max) < epsilon, `${context}/Surface: incorrect plane`);
  invariant(bounds[0].max - bounds[0].min > epsilon, `${context}/Surface: zero repeat width`);
  const secondExtent = kind === "surface_finish" ? 2 : 1;
  invariant(bounds[secondExtent].max - bounds[secondExtent].min > epsilon, `${context}/Surface: zero repeat height/depth`);
  invariant(normals.every((normal) => normal[normalAxis] > 0.999), `${context}/Surface: incorrect visible normal`);
  for (const component of [0, 1]) {
    invariant(Math.abs(Math.min(...uvs.map((uv) => uv[component]))) < epsilon, `${context}/Surface: UV minimum must be zero`);
    invariant(Math.abs(Math.max(...uvs.map((uv) => uv[component])) - 1) < epsilon, `${context}/Surface: UV maximum must be one`);
  }
  const material = gltf.materials[primitive.material];
  for (const textureInfo of [
    material.pbrMetallicRoughness?.baseColorTexture,
    material.pbrMetallicRoughness?.metallicRoughnessTexture,
    material.normalTexture,
    material.occlusionTexture,
    material.emissiveTexture,
  ].filter(Boolean)) {
    const texture = gltf.textures[textureInfo.index];
    const sampler = gltf.samplers?.[texture.sampler] ?? {};
    invariant((sampler.wrapS ?? 10497) === 10497 && (sampler.wrapT ?? 10497) === 10497, `${context}/Surface: material texture must repeat`);
  }
  return bounds[0].max - bounds[0].min;
}


function roleXBounds(gltf, roleIndex) {
  const bounds = [];
  function visit(index, parentX) {
    const node = gltf.nodes[index];
    invariant(node.matrix === undefined && node.rotation === undefined && node.scale === undefined, `${node.name}: reproducibility validator expects applied optional transforms`);
    const x = parentX + (node.translation?.[0] ?? 0);
    if (node.mesh !== undefined) {
      for (const primitive of gltf.meshes[node.mesh].primitives) {
        const accessor = gltf.accessors[primitive.attributes.POSITION];
        invariant(accessor.min !== undefined && accessor.max !== undefined, `${node.name}: POSITION bounds required`);
        bounds.push([x + accessor.min[0], x + accessor.max[0]]);
      }
    }
    for (const child of node.children ?? []) {
      visit(child, x);
    }
  }
  visit(roleIndex, 0);
  invariant(bounds.length > 0, `${gltf.nodes[roleIndex].name}: role has no mesh descendants`);
  return [Math.min(...bounds.map(([minimum]) => minimum)), Math.max(...bounds.map(([, maximum]) => maximum))];
}


function validateHierarchy(gltf, binary, kind, context) {
  const scene = gltf.scenes[gltf.scene ?? 0];
  invariant(scene.nodes?.length === 1, `${context}: exactly one scene root required`);
  const rootIndex = scene.nodes[0];
  const root = gltf.nodes[rootIndex];
  const expectedRoot = kind === "surface_finish" ? "SurfaceFinish" : "WallStyle";
  invariant(root.name === expectedRoot, `${context}: expected root ${expectedRoot}`);
  identityTransform(root, `${context}/${expectedRoot}`);
  invariant(root.mesh === undefined, `${context}/${expectedRoot}: semantic root must be empty`);

  if (kind === "surface_finish") {
    const children = directChildren(gltf, root);
    invariant(children.length === 1 && children[0].node.name === "Surface", `${context}: SurfaceFinish must contain only Surface`);
    validateSurface(gltf, binary, children[0].index, kind, context);
    return;
  }

  const sampleChildren = directChildren(gltf, root);
  uniqueChildNames(gltf, root, `${context}/WallStyle`);
  invariant(sampleChildren.some(({ node }) => node.name === "Common"), `${context}: Common sample required`);
  invariant(sampleChildren.every(({ node }) => ["Common", "Interior", "Exterior"].includes(node.name)), `${context}: unknown WallStyle child`);
  for (const { index: sampleIndex, node: sample } of sampleChildren) {
    identityTransform(sample, `${context}/${sample.name}`);
    invariant(sample.mesh === undefined, `${context}/${sample.name}: sample must be empty`);
    const roleChildren = directChildren(gltf, sample);
    uniqueChildNames(gltf, sample, `${context}/${sample.name}`);
    invariant(roleChildren.every(({ node }) => semanticRoles.has(node.name)), `${context}/${sample.name}: unknown semantic role`);
    const surface = roleChildren.find(({ node }) => node.name === "Surface");
    invariant(surface !== undefined, `${context}/${sample.name}: Surface required`);
    const moduleWidth = validateSurface(gltf, binary, surface.index, kind, `${context}/${sample.name}`);
    invariant(
      Math.abs(moduleWidth - 1.0) <= 1.0e-5,
      `${context}/${sample.name}: Wall Style module must be exactly one VTT square wide`,
    );
    for (const { index: roleIndex, node: role } of roleChildren.filter(({ node }) => node.name !== "Surface")) {
      identityTransform(role, `${context}/${sample.name}/${role.name}`);
      invariant(role.mesh === undefined, `${context}/${sample.name}/${role.name}: role must be an empty group`);
      if (["Detail", "Base", "Top"].includes(role.name)) {
        const [minimum, maximum] = roleXBounds(gltf, roleIndex);
        invariant(maximum - minimum <= moduleWidth + 1.0e-5, `${context}/${sample.name}/${role.name}: exceeds Surface module width`);
      }
    }
  }
}


function validatePng(bytes, context) {
  invariant(bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])), `${context}: invalid PNG signature`);
  invariant(bytes.subarray(12, 16).toString("ascii") === "IHDR", `${context}: IHDR must be first`);
  invariant(bytes.readUInt32BE(16) === 512 && bytes.readUInt32BE(20) === 512, `${context}: preview must be 512 x 512`);
  invariant(bytes[24] === 8 && [2, 6].includes(bytes[25]), `${context}: preview must be 8-bit RGB or RGBA`);
  const chunks = [];
  let offset = 8;
  while (offset < bytes.length) {
    const length = bytes.readUInt32BE(offset);
    const type = bytes.subarray(offset + 4, offset + 8).toString("ascii");
    chunks.push(type);
    offset += 12 + length;
    if (type === "IEND") break;
  }
  invariant(chunks.includes("sRGB"), `${context}: sRGB declaration required`);
}


function primitiveTriangleCount(gltf, primitive) {
  const elementCount = primitive.indices === undefined
    ? gltf.accessors[primitive.attributes.POSITION].count
    : gltf.accessors[primitive.indices].count;
  return elementCount / 3;
}


function totalTriangleCount(gltf) {
  return (gltf.meshes ?? []).reduce(
    (total, mesh) => total + mesh.primitives.reduce(
      (meshTotal, primitive) => meshTotal + primitiveTriangleCount(gltf, primitive),
      0,
    ),
    0,
  );
}


async function main() {
  const manifest = await readJson(join(packageRoot, "vtt.package.json"));
  const build = await readJson(join(packageRoot, "vtt.build.json"));
  invariant(manifest.package.kind === "content", "manifest: content Package required");
  invariant(manifest.entrypoints === undefined && manifest.api === undefined, "manifest: content Package must not be executable");
  const entries = manifest.content.flatMap((group) => {
    invariant(group.kind === "visual", "manifest: architectural entries must be visual content");
    return group.entries;
  });
  invariant(entries.length === 5, "manifest: expected five reference entries");
  const staticTargets = new Set();
  for (const file of build.static) {
    invariant(file.source === file.target, `build: source and target differ for ${file.source}`);
    invariant(!staticTargets.has(file.target), `build: duplicate target ${file.target}`);
    staticTargets.add(file.target);
  }

  const directories = (await readdir(contentRoot, { withFileTypes: true }))
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
  invariant(directories.length === entries.length, "content: directory and manifest entry counts differ");

  const triangleCounts = [];
  for (const entry of entries) {
    const context = entry.id;
    invariant(directories.includes(entry.id), `${context}: definition directory missing`);
    invariant(entry.payload === `content/${entry.id}/content.json`, `${context}: unexpected payload path`);
    const directory = join(contentRoot, entry.id);
    const descriptor = await readJson(join(directory, "content.json"));
    const expectedKeys = ["appearance", "displayName", "id", "kind", "preview", "schemaVersion"];
    exactKeys(descriptor, expectedKeys, `${context}/content.json`);
    invariant(descriptor.schemaVersion === 1, `${context}: schemaVersion must be 1`);
    invariant(descriptor.id === entry.id && descriptor.displayName === entry.displayName && descriptor.kind === entry.type, `${context}: descriptor/manifest mismatch`);
    invariant(["surface_finish", "wall_style"].includes(descriptor.kind), `${context}: unsupported content kind`);
    invariant(descriptor.appearance === "appearance.glb" && descriptor.preview === "preview.png", `${context}: conventional artifacts expected`);

    const glbRelative = `content/${entry.id}/${descriptor.appearance}`;
    const previewRelative = `content/${entry.id}/${descriptor.preview}`;
    invariant(staticTargets.has(glbRelative) && staticTargets.has(previewRelative), `${context}: artifacts absent from vtt.build.json`);
    const glbPath = join(directory, descriptor.appearance);
    const previewPath = join(directory, descriptor.preview);
    invariant((await stat(glbPath)).size > 0, `${context}: empty GLB`);
    invariant((await stat(join(authoringRoot, "blend", `${entry.id}.blend`))).size > 0, `${context}: editable Blender source missing`);
    validatePng(await readFile(previewPath), `${context}/preview.png`);
    const { gltf, binary } = parseGlb(await readFile(glbPath), `${context}/appearance.glb`);
    validatePrimitiveProfile(gltf, `${context}/appearance.glb`);
    validateHierarchy(gltf, binary, descriptor.kind, `${context}/appearance.glb`);
    const triangleCount = totalTriangleCount(gltf);
    const triangleBudget = descriptor.kind === "surface_finish" ? 2 : 2_000;
    invariant(
      triangleCount <= triangleBudget,
      `${context}/appearance.glb: exceeds ${triangleBudget}-triangle fixture budget`,
    );
    triangleCounts.push(`${context}: ${triangleCount}`);
  }

  invariant(staticTargets.size === entries.length * 2, "build: unexpected static artifact count");
  console.log(`validated ${entries.length} architectural definitions, ${staticTargets.size} static artifacts, and five editable Blender sources`);
  console.log(`triangles — ${triangleCounts.join(", ")}`);
}


await main();
