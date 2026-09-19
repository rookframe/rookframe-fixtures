"""Refine the editable approval draft in the same Blender MCP session."""
import bpy
import numpy as np
from pathlib import Path

OUT = Path('/Users/artembohulenkov/Projects/rookframe-godot/artifacts/rfg-261-bookshelf')
texdir=OUT/'textures'
texdir.mkdir(exist_ok=True)
asset=bpy.data.collections['Bookshelf — approval draft']
# Make space for the leaning end volumes instead of allowing intersecting books.
for row in (1,3,5):
    candidates=[o for o in asset.objects if o.type=='EMPTY' and o.name.startswith('Book %02d-'%row)]
    for ob in candidates:
        if ob.location.x > .40:
            for child in list(ob.children): bpy.data.objects.remove(child,do_unlink=True)
            bpy.data.objects.remove(ob,do_unlink=True)
        else:
            ob.rotation_euler.y=0

def image_data(name,pixels):
    im=bpy.data.images.new(name,width=pixels.shape[1],height=pixels.shape[0])
    im.colorspace_settings.name='Non-Color'
    im.pixels.foreach_set(pixels.astype('float32').reshape(-1))
    im.filepath_raw=str(texdir/(name+'.png'))
    im.file_format='PNG'
    im.save()
    im.pack()
    return im

# Modest mottling and fine pores; ordinary image textures, ready for glTF.
n=256
rr=np.random.default_rng(261)
grain=rr.random((n,n))
cloud=rr.random((n,n))
for _ in range(40):
    cloud=(cloud+np.roll(cloud,1,0)+np.roll(cloud,-1,0)+np.roll(cloud,1,1)+np.roll(cloud,-1,1))/5
cloud=(cloud-cloud.min())/(cloud.max()-cloud.min())
leathers=[m for m in bpy.data.materials if m.name.startswith('Leather — ')]
for j,mat in enumerate(leathers):
    bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    base=np.array(bs.inputs['Base Color'].default_value[:3])
    variation=.70+.34*np.roll(cloud,j*23,0)+.13*grain
    rgba=np.ones((n,n,4))
    rgba[:,:,:3]=np.minimum(base[None,None,:]*variation[:,:,None],1)
    im=image_data('leather-'+str(j),rgba)
    node=mat.node_tree.nodes.new('ShaderNodeTexImage')
    node.image=im
    mat.node_tree.links.new(node.outputs['Color'],bs.inputs['Base Color'])

norm=np.ones((n,n,4))
norm[:,:,0]=.5+(grain-np.roll(grain,1,1))*.11
norm[:,:,1]=.5+(grain-np.roll(grain,1,0))*.11
norm[:,:,2]=1
pores=image_data('leather-pores-normal',norm)
for mat in leathers:
    bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    texture=mat.node_tree.nodes.new('ShaderNodeTexImage')
    texture.image=pores
    normal=mat.node_tree.nodes.new('ShaderNodeNormalMap')
    normal.inputs['Strength'].default_value=.24
    mat.node_tree.links.new(texture.outputs['Color'],normal.inputs['Color'])
    mat.node_tree.links.new(normal.outputs['Normal'],bs.inputs['Normal'])

bpy.context.scene.render.filepath=str(OUT/'bookshelf-hero.png')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'bookshelf-approval.blend'))
print('Refined leather texture and cleared intersections at leaning books.')
