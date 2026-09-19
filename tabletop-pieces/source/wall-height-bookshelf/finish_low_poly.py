"""Assemble the baked low-poly asset and render its actual runtime appearance."""
import bpy
import json
import numpy as np
from mathutils import Vector
from pathlib import Path

OUT=Path('/Users/artembohulenkov/Projects/rookframe-godot/artifacts/rfg-261-bookshelf')
scene=bpy.context.scene
low=bpy.data.objects['WallHeightBookshelf']
for start,end,offset in json.loads(low['bake_restore_ranges']):
    for i in range(start,end): low.data.vertices[i].co-=Vector(offset)
del low['bake_restore_ranges']
low.data.update()
mat=low.data.materials[0]
mat.name='Bookshelf — baked PBR'
mat.use_backface_culling=True
nodes=mat.node_tree.nodes; links=mat.node_tree.links
for n in list(nodes):
    if n.type not in ('BSDF_PRINCIPLED','OUTPUT_MATERIAL'): nodes.remove(n)
bs=next(n for n in nodes if n.type=='BSDF_PRINCIPLED')

def texture(name,colorspace):
    image=bpy.data.images[name]
    image.colorspace_settings.name=colorspace
    n=nodes.new('ShaderNodeTexImage'); n.image=image
    return n

albedo=texture('bookshelf-albedo','sRGB')
normaltex=texture('bookshelf-normal','Non-Color')
links.new(albedo.outputs['Color'],bs.inputs['Base Color'])
normal=nodes.new('ShaderNodeNormalMap')
links.new(normaltex.outputs['Color'],normal.inputs['Color'])
links.new(normal.outputs['Normal'],bs.inputs['Normal'])
n=2048
orm=np.ones((n*n,4),dtype='float32')
for name,channel in [('bookshelf-roughness',1),('bookshelf-metallic',2)]:
    pixels=np.empty(n*n*4,dtype='float32')
    bpy.data.images[name].pixels.foreach_get(pixels)
    orm[:,channel]=pixels.reshape((-1,4))[:,0]
im=bpy.data.images.new('bookshelf-orm',width=n,height=n)
im.colorspace_settings.name='Non-Color'
im.pixels.foreach_set(orm.reshape(-1))
im.filepath_raw=str(OUT/'bookshelf-orm.png')
im.file_format='PNG'; im.save(); im.pack()
ormtex=texture('bookshelf-orm','Non-Color')
separate=nodes.new('ShaderNodeSeparateColor')
links.new(ormtex.outputs['Color'],separate.inputs['Color'])
links.new(separate.outputs['Green'],bs.inputs['Roughness'])
links.new(separate.outputs['Blue'],bs.inputs['Metallic'])

for ob in scene.objects:
    source=ob.name in bpy.data.collections['Bookshelf — approval draft'].objects
    bake=ob.name in bpy.data.collections['Temporary texture bake'].objects
    ob.hide_render=source or bake
    ob.hide_set(source or bake)
low.hide_render=False; low.hide_set(False)
scene.render.engine='BLENDER_EEVEE'
for ob in bpy.context.selected_objects: ob.select_set(False)
low.select_set(True)
bpy.context.view_layer.objects.active=low
low['dimensions_m']=[1.5,.5,2.8]
low['approval_status']='Low-poly revision — pending user approval'
low.data.calc_loop_triangles()
report={'sourceTriangles':87036,'lowPolyTriangles':len(low.data.loop_triangles),
    'reductionPercent':round((1-len(low.data.loop_triangles)/87036)*100,2),
    'meshObjects':1,'materials':len(low.data.materials),'textureSize':2048,
    'textureMaps':['albedo','normal','packed roughness/metallic'],
    'books':61,'dimensionsMeters':[1.5,.5,2.8]}
(OUT/'low-poly-metrics.json').write_text(json.dumps(report,indent=2)+'\n')
scene.render.filepath=str(OUT/'bookshelf-low-poly-comparison.png')
bpy.ops.export_scene.gltf(filepath=str(OUT/'bookshelf-low-poly.glb'),
                         use_selection=True,use_active_scene=True,
                         export_animations=False,export_tangents=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'bookshelf-low-poly.blend'))
print(json.dumps(report))
def render_low():
    bpy.ops.render.render(write_still=True)
    return None
bpy.app.timers.register(render_low,first_interval=.5)
