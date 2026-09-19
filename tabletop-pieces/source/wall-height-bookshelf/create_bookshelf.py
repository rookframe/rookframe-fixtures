"""Editable approval draft. Run in the live Blender session through Blender MCP."""
import bpy
import math
import random
from pathlib import Path
from mathutils import Vector

ROOT = Path('/Users/artembohulenkov/Projects/rookframe-godot')
OUT = ROOT / 'artifacts/rfg-261-bookshelf'
OUT.mkdir(parents=True, exist_ok=True)
scene = bpy.context.scene
asset = bpy.data.collections.new('Bookshelf — approval draft')
scene.collection.children.link(asset)
stage = bpy.data.collections.new('Approval lighting and floor')
scene.collection.children.link(stage)
rng = random.Random(261)
wood = bpy.data.materials['Weathered Oak Timber']

def linear(v):
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4

def material(name, hex_color, roughness=0.75, metal=0.0):
    rgb = [linear(int(hex_color[i:i+2], 16) / 255) for i in (0, 2, 4)]
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, 1)
    mat.use_nodes = True
    node = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value = (*rgb, 1)
    node.inputs['Roughness'].default_value = roughness
    node.inputs['Metallic'].default_value = metal
    return mat

iron = material('Forged iron — dark worn fittings', '3d3931', .74, .65)
gold = material('Tarnished gilt tooling', 'a48b52', .62, .50)
pages = material('Aged parchment edges', 'bbae89', .91)
page_line = material('Parchment edge shadows', '9b8c68', .94)
leathers = [material('Leather — ' + name, color, .80) for name, color in [
    ('oxblood', '59352f'), ('moss', '4d5843'), ('ochre', '806444'),
    ('slate', '3c515c'), ('umber', '514034'), ('faded russet', '785143'),
    ('charcoal', '393b35'), ('sage', '626850')]]

def box(name, dims, pos, mat, bevel=.003, collection=asset, parent=None, grain=2):
    x, y, z = (v * .5 for v in dims)
    verts = [(-x,-y,-z), (x,-y,-z), (x,y,-z), (-x,y,-z),
             (-x,-y,z), (x,-y,z), (x,y,z), (-x,y,z)]
    faces = [(0,3,2,1), (4,5,6,7), (0,1,5,4), (1,2,6,5), (2,3,7,6), (3,0,4,7)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    uv = mesh.uv_layers.new(name='UVMap')
    offset = rng.random()
    for face in mesh.polygons:
        axes = [a for a in range(3) if abs(face.normal[a]) < .5]
        if grain in axes:
            a, b = next(a for a in axes if a != grain), grain
        else:
            a, b = axes
        for loop in face.loop_indices:
            co = mesh.vertices[mesh.loops[loop].vertex_index].co
            uv.data[loop].uv = (co[a] * 1.5 + offset, co[b] * .72 + offset)
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.location = pos
    obj.parent = parent
    mesh.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new('Soft worn edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 2
    return obj

root = bpy.data.objects.new('Wall-height Bookshelf | 1.50 × 0.48 × 2.80 m', None)
asset.objects.link(root)
root['dimensions_m'] = [1.5, .48, 2.8]
root['approval_status'] = 'Draft — awaiting user approval before Package publication'

# Solid, closed back with individually readable oak boards.
box('Solid back core', (1.32,.024,2.47), (0,.215,1.415), wood, .002, parent=root)
for i in range(8):
    box('Back board %02d' % (i+1), (.162,.022,2.47), ((i-3.5)*.165,.194,1.415), wood, .002, parent=root)
for x in (-.68,.68):
    box('Full-height side', (.10,.42,2.53), (x,0,1.415), wood, .009, parent=root)
    box('Front stile', (.115,.085,2.55), (x,-.207,1.415), wood, .008, parent=root)
    box('Foot', (.13,.43,.18), (x,0,.09), wood, .008, parent=root)

for name, dim, loc in [
    ('Plinth', (1.48,.47,.11), (0,0,.14)),
    ('Plinth bead', (1.44,.44,.045), (0,-.006,.216)),
    ('Upper frieze', (1.40,.43,.12), (0,0,2.675)),
    ('Crown lower moulding', (1.45,.45,.045), (0,0,2.738)),
    ('Crown cap', (1.50,.48,.04), (0,0,2.78))]:
    box(name,dim,loc,wood,.006,parent=root,grain=0)

bases = [.265, .745, 1.225, 1.705, 2.185]
for j, z in enumerate(bases):
    box('Shelf %d' % (j+1), (1.28,.405,.045), (0,-.007,z-.0225), wood,.005,parent=root,grain=0)
    box('Shelf front lip %d' % (j+1), (1.30,.035,.060), (0,-.211,z-.028), wood,.003,parent=root,grain=0)
    for x in (-.68,.68):
        box('Iron shelf peg',(.027,.012,.027),(x,-.254,z-.033),iron,.004,parent=root)

book_count = 0
def book(name, width, depth, height, x, y, z, color, lean=0, horizontal=False, yaw=0):
    global book_count
    book_count += 1
    group = bpy.data.objects.new(name, None)
    asset.objects.link(group)
    group.parent = root
    group.location = (x,y,z)
    group.rotation_euler = (0, math.pi*.5 if horizontal else lean, yaw)
    box(name+' page block',(width-.013,depth-.017,height-.018),(0,.006,height*.5),pages,.002,parent=group)
    for side in (-1,1):
        box(name+' leather board',(.006,depth,height),(side*(width*.5-.003),0,height*.5),color,.003,parent=group)
    box(name+' rounded spine',(width,.022,height),(0,-depth*.5+.002,height*.5),color,.009,parent=group)
    for p in (.16,.30,.73,.88):
        box(name+' raised binding',(width+.003,.025,.009),(0,-depth*.5-.001,height*p),color,.003,parent=group)
    # Sparse gilt rules and a worn central label read from tabletop distance.
    for p in (.37,.62):
        box(name+' gilt rule',(width*.67,.002,.0025),(0,-depth*.5-.010,height*p),gold,.0005,parent=group)
    box(name+' label',(width*.52,.002,.034),(0,-depth*.5-.010,height*.51),gold,.001,parent=group)
    box(name+' label inset',(width*.43,.002,.023),(0,-depth*.5-.0115,height*.51),color,.001,parent=group)
    # A few uneven page-edge strata; modeled detail survives glTF export.
    for p in (.18,.34,.53,.69,.85):
        box(name+' page stratum',(width-.018,.0015,.0013),(0,depth*.5-.003,height*p),page_line,0,parent=group)
    return group

for row,z in enumerate(bases):
    x=-.612
    stop=.20 if row in (1,3) else .58
    k=0
    while x < stop-.075:
        w=rng.uniform(.056,.105)
        h=rng.uniform(.29,.412)
        d=rng.uniform(.235,.31)
        if x+w > stop: break
        book('Book %02d-%02d'%(row+1,k+1),w,d,h,x+w*.5,-.040+rng.uniform(-.018,.025),z,leathers[(row*3+k)%len(leathers)],lean=rng.uniform(-.025,.025))
        x+=w+rng.uniform(.007,.014)
        k+=1
    if row in (1,3):
        # Lying folios beside standing volumes, with a natural untidy stack.
        stack=z
        for k in range(3):
            thick=.053+k*.009
            book('Stacked folio %d-%d'%(row,k),thick,.30,.32,.245,-.04,stack+thick*.5,leathers[(row+k+2)%len(leathers)],horizontal=True,yaw=(-.04+k*.035))
            stack+=thick+.005
    else:
        book('Leaning end volume %d'%row,.075,.29,.37,.54,-.044,z+.015,leathers[(row+3)%len(leathers)],lean=-.19)

floor=material('Studio charcoal', '353836', .95)
box('Preview ground',(200,200,.10),(0,0,-.055),floor,0,collection=stage)
world=bpy.data.worlds.new('Bookshelf studio')
scene.world=world
world.use_nodes=True
bg=next(n for n in world.node_tree.nodes if n.type=='BACKGROUND')
bg.inputs[0].default_value=(.12,.14,.16,1)
bg.inputs[1].default_value=.45
def area(name, pos, energy, size, color):
    data=bpy.data.lights.new(name,'AREA')
    data.energy=energy
    data.shape=next(e.identifier for e in data.bl_rna.properties['shape'].enum_items if e.identifier=='DISK')
    data.size=size
    data.color=color
    ob=bpy.data.objects.new(name,data)
    stage.objects.link(ob)
    ob.location=pos
    ob.rotation_euler=(Vector((0,0,1.3))-ob.location).to_track_quat('-Z','Y').to_euler()
area('Large warm key',(-3,-4,5.5),600,4,(1,.87,.70))
area('Cool soft fill',(3,-2,3),360,3,(.72,.83,1))
area('Top rim',(1,2,4.5),500,3,(1,.91,.78))
camdata=bpy.data.cameras.new('Approval camera')
camera=bpy.data.objects.new('Approval camera',camdata)
stage.objects.link(camera)
camera.location=(4.2,-7.7,4.0)
camera.rotation_euler=(Vector((0,0,1.40))-camera.location).to_track_quat('-Z','Y').to_euler()
camdata.type='ORTHO'
camdata.ortho_scale=3.7
scene.camera=camera
scene.render.resolution_x=1300
scene.render.resolution_y=1500
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.render.image_settings.color_mode='RGB'
scene.render.filepath=str(OUT/'bookshelf-hero.png')
scene.render.film_transparent=False
for a in bpy.context.screen.areas:
    if a.type=='VIEW_3D':
        a.spaces.active.region_3d.view_perspective='CAMERA'
        a.spaces.active.shading.type='MATERIAL'
        a.spaces.active.overlay.show_overlays=False
print('Created',book_count,'books,',len(asset.objects),'editable objects; dimensions 1.5 × .48 × 2.8 m')
