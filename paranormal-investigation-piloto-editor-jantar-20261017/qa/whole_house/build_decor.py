from pathlib import Path
root=Path('/workspace/The-Paranormal/paranormal-investigation-piloto-editor-jantar-20261017')
dec=root/'prototype/whole_house/decor'; dec.mkdir(parents=True,exist_ok=True)
# model path, name, position, scale, collision size, collision y
rooms={
'lavanderia':[
 ('WasherDryer','res://prototype/assets/models/innerscene/washer-dryer.glb',(-7.2,0.43,-3.9),(1,1,1),(0.60,0.86,0.60),0.43),
 ('Dryer','res://prototype/assets/models/innerscene/tumble-dryer.glb',(-6.5,0.43,-3.9),(1,1,1),(0.60,0.85,0.61),0.43),
 ('LaundryTub','res://prototype/assets/models/innerscene/utility-laundry-tub.glb',(-5.75,0.42,-3.9),(1,1,1),(1.15,0.84,0.60),0.42),
 ('LaundryShelf','res://prototype/assets/models/polyhaven/wooden_display_shelves_01/wooden_display_shelves_01_1k.gltf',(-4.85,1.1,-3.7),(0.72,0.72,0.72),(1.0,1.8,0.35),0.9),
 ('LaundryBasket','res://prototype/assets/models/polyhaven/wicker_basket_01/wicker_basket_01_1k.gltf',(-4.1,0.25,-3.8),(0.7,0.7,0.7),(0.55,0.5,0.55),0.25),
],
'deposito':[
 ('StorageRack','res://prototype/assets/models/polyhaven/worn_metal_rack/worn_metal_rack_1k.gltf',(-7.2,0.9,-1.8),(0.8,0.8,0.8),(1.2,1.8,0.5),0.9),
 ('StorageCrateA','res://prototype/assets/models/polyhaven/wooden_crate_01/wooden_crate_01_1k.gltf',(-6.2,0.25,-1.7),(0.75,0.75,0.75),(0.7,0.5,0.7),0.25),
 ('StorageCrateB','res://prototype/assets/models/polyhaven/wooden_crate_01/wooden_crate_01_1k.gltf',(-5.5,0.25,-1.7),(0.75,0.75,0.75),(0.7,0.5,0.7),0.25),
 ('SeasonalCabinet','res://prototype/assets/models/polyhaven/vintage_cabinet_01/vintage_cabinet_01_1k.gltf',(-4.35,1.0,-1.8),(0.75,0.75,0.75),(1.0,1.9,0.55),0.95),
],
'oficina':[
 ('Workbench','res://prototype/assets/models/innerscene/workbench-with-pegboard.glb',(-1.0,0.72,-6.8),(1,1,1),(1.55,1.45,0.72),0.72),
 ('ToolCart','res://prototype/assets/models/polyhaven/tool_cart/tool_cart_1k.gltf',(1.2,0.48,-6.4),(0.72,0.72,0.72),(0.75,0.95,0.58),0.48),
 ('PartsShelf','res://prototype/assets/models/polyhaven/wooden_bookshelf_worn/wooden_bookshelf_worn_1k.gltf',(3.0,1.1,-6.8),(0.72,0.72,0.72),(0.9,1.8,0.38),0.9),
 ('PartsCrate','res://prototype/assets/models/polyhaven/plastic_crate_01/plastic_crate_01_1k.gltf',(3.9,0.25,-6.0),(0.65,0.65,0.65),(0.65,0.45,0.65),0.23),
],
'circulacao':[
 ('CirculationBasket','res://prototype/assets/models/polyhaven/wicker_basket_01/wicker_basket_01_1k.gltf',(0.0,0.24,0.0),(0.55,0.55,0.55),(0.45,0.45,0.45),0.23),
],
'arquivo_sotao':[
 ('MemoryBookcase','res://prototype/assets/models/innerscene/filled-bookshelf-large-original-interior-furnishing.glb',(-2.45,0.95,1.8),(1,1,1),(1.45,1.9,0.42),0.95),
 ('MemoryDesk','res://prototype/assets/models/innerscene/desk-with-chair-original-hotel-furnishing.glb',(-0.25,0.72,1.8),(0.9,0.9,0.9),(1.25,1.35,0.75),0.68),
 ('ArchiveCabinet','res://prototype/assets/models/polyhaven/vintage_cabinet_01/vintage_cabinet_01_1k.gltf',(1.75,1.0,1.8),(0.68,0.68,0.68),(0.95,1.75,0.55),0.88),
 ('ArchiveBooks','res://prototype/assets/models/polyhaven/book_encyclopedia_set_01/book_encyclopedia_set_01_1k.gltf',(-1.6,1.9,1.8),(0.5,0.5,0.5),(0.7,0.4,0.5),2.0),
 ('ArchiveBinder','res://prototype/assets/models/polyhaven/binder_notebook/binder_notebook_1k.gltf',(-0.25,1.55,1.8),(0.55,0.55,0.55),(0.35,0.3,0.35),1.5),
],
'deposito_sotao':[
 ('SeasonalRack','res://prototype/assets/models/polyhaven/wooden_display_shelves_01/wooden_display_shelves_01_1k.gltf',(-2.0,1.0,2.0),(0.72,0.72,0.72),(1.0,1.8,0.35),0.9),
 ('SeasonalCrateA','res://prototype/assets/models/polyhaven/wooden_crate_01/wooden_crate_01_1k.gltf',(-0.7,0.25,2.05),(0.72,0.72,0.72),(0.68,0.5,0.68),0.25),
 ('SeasonalCrateB','res://prototype/assets/models/polyhaven/wooden_crate_01/wooden_crate_01_1k.gltf',(0.0,0.25,2.05),(0.72,0.72,0.72),(0.68,0.5,0.68),0.25),
 ('SeasonalCabinet','res://prototype/assets/models/polyhaven/vintage_cabinet_01/vintage_cabinet_01_1k.gltf',(1.45,1.0,2.05),(0.68,0.68,0.68),(0.95,1.75,0.55),0.88),
]
}

def esc(p): return p
for key, items in rooms.items():
 lines=['[gd_scene load_steps=%d format=3]'%(1+len(items)*2)]
 for i,(name,path,*_) in enumerate(items): lines.append(f'[ext_resource type="PackedScene" path="{path}" id="{i+1}_model"]')
 for i,(name,path,pos,scale,size,cy) in enumerate(items): lines.append(f'[sub_resource type="BoxShape3D" id="{i+1}_shape"]\nsize = Vector3({size[0]}, {size[1]}, {size[2]})')
 lines.append(f'[node name="Decor_{key}" type="Node3D"]\nmetadata/ambient_role = "{key}"\nmetadata/_edit_group_ = true')
 for i,(name,path,pos,scale,size,cy) in enumerate(items):
  lines.append(f'''[node name="{name}" type="Node3D" parent="." unique_id={700000000+i+len(key)*1000}]
position = Vector3({pos[0]}, {pos[1]}, {pos[2]})
scale = Vector3({scale[0]}, {scale[1]}, {scale[2]})
metadata/_edit_group_ = true
metadata/persistent_prop = true
[node name="Model" parent="{name}" instance=ExtResource("{i+1}_model")]
[node name="Collision" type="StaticBody3D" parent="{name}"]
[node name="Shape" type="CollisionShape3D" parent="{name}/Collision"]
position = Vector3(0, {cy}, 0)
shape = SubResource("{i+1}_shape")''')
 (dec/(key+'.tscn')).write_text('\n'.join(lines)+'\n')
 print('wrote',key)
