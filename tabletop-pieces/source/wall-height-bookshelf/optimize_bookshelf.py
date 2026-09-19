"""Create a low-poly bookshelf and bake source detail with stock Blender tools.

Run through Blender MCP with bookshelf-approval.blend open. Source objects are
preserved. Separated baking groups prevent adjacent books contaminating maps.
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Matrix, Vector

OUT=Path('/Users/artembohulenkov/Projects/rookframe-godot/artifacts/rfg-261-bookshelf')
scene=bpy.context.scene
source=bpy.data.collections['Bookshelf — approval draft']
runtime=bpy.data.collections.new('Bookshelf — low poly')
scene.collection.children.link(runtime)
bake_collection=bpy.data.collections.new('Temporary texture bake')
scene.collection.children.link(bake_collection)
source_meshes=[o for o in source.objects if o.type=='MESH']
source_mats=list(dict.fromkeys(s.material for o in source_meshes for s in o.material_slots))
bake_mats=[m.copy() for m in source_mats]
for m in bake_mats: m.name='Bake source '+m.name
deps=bpy.context.evaluated_depsgraph_get()

def blank_box(name,lo,hi):
    x,y,z=lo; X,Y,Z=hi
    verts=[(x,y,z),(X,y,z),(X,Y,z),(x,Y,z),(x,y,Z),(X,y,Z),(X,Y,Z),(x,Y,Z)]
    faces=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(verts,[],faces)
    mesh.update()
    ob=bpy.data.objects.new(name,mesh)
    bake_collection.objects.link(ob)
    return ob

groups=[]
book_roots=[o for o in source.objects if o.type=='EMPTY'
            and o.name.startswith(('Book ','Stacked folio','Leaning end'))]
for book in book_roots:
    children=[o for o in book.children if o.type=='MESH']
    points=[o.matrix_local@Vector(v) for o in children for v in o.bound_box]
    lo=[min(v[a] for v in points) for a in range(3)]
    hi=[max(v[a] for v in points) for a in range(3)]
    ob=blank_box('Low '+book.name,lo,hi)
    ob.matrix_world=book.matrix_world.copy()
    mod=ob.modifiers.new('Silhouette bevel','BEVEL')
    mod.width=.002
    mod.segments=1
    groups.append((children,ob))

remaining=[o for o in source_meshes if o.parent not in book_roots]
back=[o for o in remaining if o.name.startswith(('Solid back core','Back board'))]
ob=blank_box('Low closed oak back',(-.66,.183,.18),(.66,.227,2.65))
groups.append((back,ob))
remaining=[o for o in remaining if o not in back]
pegs=[o for o in remaining if o.name.startswith('Iron shelf peg')]
for original in [o for o in remaining if o not in pegs]:
    members=[original]
    if original.name.startswith('Front stile'):
        members += [p for p in pegs if abs(p.location.x-original.location.x)<.01]
    ob=original.copy()
    ob.data=original.data.copy()
    ob.parent=None
    ob.matrix_world=original.matrix_world.copy()
    bake_collection.objects.link(ob)
    for m in ob.modifiers:
        if m.type=='BEVEL': m.segments=1
    groups.append((members,ob))

class MeshBuilder:
    def __init__(self):
        self.vertices=[]; self.faces=[]; self.uvs=[]; self.materials=[]
    def add(self,ob,offset,with_materials):
        evaluated=ob.evaluated_get(deps)
        mesh=evaluated.to_mesh()
        matrix=Matrix.Translation(offset)@ob.matrix_world
        start=len(self.vertices)
        self.vertices.extend(tuple(matrix@v.co) for v in mesh.vertices)
        uv=mesh.uv_layers.active
        for p in mesh.polygons:
            self.faces.append(tuple(start+v for v in p.vertices))
            self.uvs.extend(tuple(uv.data[l].uv) if uv else (0,0) for l in p.loop_indices)
            mat=mesh.materials[p.material_index] if with_materials else None
            self.materials.append(source_mats.index(mat.original) if mat else 0)
        evaluated.to_mesh_clear()
        return start,len(self.vertices)
    def object(self,name,collection,mats):
        mesh=bpy.data.meshes.new(name)
        mesh.from_pydata(self.vertices,[],self.faces)
        mesh.update()
        uv=mesh.uv_layers.new(name='UVMap')
        for i,v in enumerate(self.uvs): uv.data[i].uv=v
        for m in mats: mesh.materials.append(m)
        for i,p in enumerate(mesh.polygons): p.material_index=self.materials[i]
        ob=bpy.data.objects.new(name,mesh)
        collection.objects.link(ob)
        return ob

bpy.context.view_layer.update()
high_builder=MeshBuilder(); low_builder=MeshBuilder(); restore_ranges=[]
for i,(members,low_part) in enumerate(groups):
    offset=Vector((5*(i%10),5*(i//10),0))
    for member in members: high_builder.add(member,offset,True)
    start,end=low_builder.add(low_part,offset,False)
    restore_ranges.append((start,end,tuple(offset)))
for _,ob in groups: bpy.data.objects.remove(ob,do_unlink=True)
high=high_builder.object('Exploded source',bake_collection,bake_mats)
atlas_mat=bpy.data.materials.new('Bookshelf PBR atlas')
atlas_mat.use_nodes=True
low=low_builder.object('WallHeightBookshelf',runtime,[atlas_mat])
low['bake_restore_ranges']=json.dumps(restore_ranges)
for ob in bpy.context.selected_objects: ob.select_set(False)
low.select_set(True)
bpy.context.view_layer.objects.active=low
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.003,
                        margin_method='FRACTION',area_weight=0.0)
bpy.ops.object.mode_set(mode='OBJECT')
low.data.calc_loop_triangles()
print('Low-poly geometry:',len(low.data.loop_triangles),'triangles;',len(groups),'baking groups')

images={}
for key in ('albedo','normal','roughness','metallic'):
    im=bpy.data.images.new('bookshelf-'+key,width=2048,height=2048)
    im.colorspace_settings.name='sRGB' if key=='albedo' else 'Non-Color'
    images[key]=im
target=atlas_mat.node_tree.nodes.new('ShaderNodeTexImage')
atlas_mat.node_tree.nodes.active=target
target.select=True
original_render_visibility={ob:ob.hide_render for ob in scene.objects}
for ob in scene.objects:
    ob.hide_render=ob not in (low,high)
    if ob.name in source.objects: ob.hide_set(True)
high.select_set(True)
scene.render.engine='CYCLES'
scene.cycles.device='CPU'
scene.cycles.samples=4

def output_channel(channel):
    for mat in bake_mats:
        nodes=mat.node_tree.nodes; links=mat.node_tree.links
        bs=next(n for n in nodes if n.type=='BSDF_PRINCIPLED')
        output=next(n for n in nodes if n.type=='OUTPUT_MATERIAL')
        for link in list(output.inputs['Surface'].links): links.remove(link)
        if channel=='normal':
            links.new(bs.outputs[0],output.inputs['Surface'])
            continue
        emit=next((n for n in nodes if n.type=='EMISSION'),None)
        if emit is None: emit=nodes.new('ShaderNodeEmission')
        for link in list(emit.inputs[0].links): links.remove(link)
        socket=bs.inputs[{'albedo':'Base Color','roughness':'Roughness','metallic':'Metallic'}[channel]]
        if socket.is_linked:
            links.new(socket.links[0].from_socket,emit.inputs[0])
        else:
            v=socket.default_value
            emit.inputs[0].default_value=tuple(v) if channel=='albedo' else (v,v,v,1)
        emit.inputs[1].default_value=1
        links.new(emit.outputs[0],output.inputs['Surface'])

jobs=iter(('albedo','normal','roughness','metallic'))
progress=OUT/'low-poly-progress.txt'
def bake_next():
    try:
        key=next(jobs)
    except StopIteration:
        progress.write_text('bake complete\n')
        return None
    progress.write_text('baking '+key+'\n')
    output_channel(key)
    target.image=images[key]
    bpy.ops.object.bake(type='NORMAL' if key=='normal' else 'EMIT',
        use_selected_to_active=True,cage_extrusion=.035,max_ray_distance=.10,
        normal_space='TANGENT',margin=5,use_clear=True)
    im=images[key]
    im.filepath_raw=str(OUT/('bookshelf-'+key+'.png'))
    im.file_format='PNG'; im.save(); im.pack()
    progress.write_text('finished '+key+'\n')
    return .5
bpy.app.timers.register(bake_next,first_interval=.5)
