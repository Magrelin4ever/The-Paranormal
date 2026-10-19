#!/usr/bin/env python3
"""Gera adaptador offline: preserva a fonte GitHub e grava nós nativos, sem rebuild no jogo."""
from pathlib import Path
import re
ROOT = Path(__file__).resolve().parents[2]
src = (ROOT/'prototype/house_environment.gd').read_text()
head = '''extends "res://prototype/house_environment.gd"
# Adaptador OFFLINE. Só qa/whole_house/bake_house.gd o executa.
var bake_phase := "Estrutura"
var bake_serial := 0
var bake_box_count := 0
var bake_triangle_count := 0

func _ready() -> void:
	set_process(false)
	_criar_materiais()
	_raiz_visual = Node3D.new()
	_raiz_visual.name = "ConteudoConvertido"
	add_child(_raiz_visual)
	_criar_corpos_colisao()
	for method in ["_montar_pisos_e_estrutura", "_montar_paredes_internas", "_montar_escadas", "_montar_telhado_exterior", "_mobiliar_porao", "_mobiliar_terreo", "_mobiliar_primeiro_andar", "_mobiliar_sotao", "_montar_vizinhanca"]:
		bake_phase = method
		call(method)
	_apagar_luzes_internas()

func bake_enter(label: String, piso: StringName = &"") -> Node3D:
	var item := Node3D.new()
	bake_serial += 1
	item.name = "%s_%03d" % [label, bake_serial]
	item.set_meta("origem_conversao", label)
	item.set_meta("fase_conversao", bake_phase)
	item.set_meta("pavimento", piso)
	item.set_meta("_edit_group_", true)
	_raiz_visual.add_child(item)
	_raiz_visual = item
	return item

func bake_exit(previous: Node3D, item: Node3D, pivot: Vector3) -> void:
	_raiz_visual = previous
	# Os helpers originais escrevem coordenadas da casa. Recentrar conserva o mundo.
	for child in item.get_children():
		if child is Node3D and not child.top_level:
			child.position -= pivot
	item.position = pivot
	item.set_meta("pivot_original", pivot)

func bake_body(parent: Node3D, center: Vector3, size: Vector3, angle: Vector3, label: String) -> void:
	var body := StaticBody3D.new()
	body.name = label.validate_node_name()
	body.collision_layer = 1
	body.collision_mask = 1
	body.position = center
	body.rotation = angle
	parent.add_child(body)
	var shape := CollisionShape3D.new()
	shape.name = "Forma"
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	body.add_child(shape)

func _adicionar_colisao_caixa(center: Vector3, size: Vector3, floor_id: StringName, collider_name: StringName, rotation: Vector3 = Vector3.ZERO) -> void:
	# Colisão pertence à peça, nunca a um corpo global fixo.
	bake_body(_raiz_visual, center, size, rotation, String(collider_name))

func _finalizar_malhas_visuais() -> void:
	pass # Cada peça já tem malha própria e editável.

func _adicionar_triangulo(a: Vector3, b: Vector3, c: Vector3, material_key: StringName) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(_materiais[material_key])
	var pivot := (a+b+c)/3.0
	var normal := (b-a).cross(c-a).normalized()
	for vertex in [a,b,c]:
		st.set_normal(normal)
		st.set_uv(Vector2.ZERO)
		st.add_vertex(vertex-pivot)
	var mesh := MeshInstance3D.new()
	bake_triangle_count += 1
	mesh.name = "Triangulo_%s_%03d" % [material_key, bake_triangle_count]
	mesh.mesh = st.commit()
	mesh.position = pivot
	mesh.set_meta("fase_conversao", bake_phase)
	_raiz_visual.add_child(mesh)

func _adicionar_tubo_servico_c17(a: Vector3, b: Vector3, raio: float, material_key: StringName) -> void:
	var direction := b-a
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = raio
	cylinder.bottom_radius = raio
	cylinder.height = direction.length()
	cylinder.radial_segments = 16
	cylinder.rings = 1
	var mesh := MeshInstance3D.new()
	mesh.name = "Tubo_%s" % material_key
	mesh.mesh = cylinder
	mesh.material_override = _materiais[material_key]
	mesh.position = (a+b)*0.5
	mesh.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
	mesh.set_meta("fase_conversao", bake_phase)
	_raiz_visual.add_child(mesh)
'''
# Conserva UVs, normais, material, dimensões e rotações de cada caixa da fonte.
box = re.search(r'func _adicionar_caixa\(.*?(?=\nfunc )', src, re.S).group()
box = box[:box.index('\n\tif solid and')]
box = box.replace('var tool: SurfaceTool = _ferramentas_superficie[material_key]', '''var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(_materiais[material_key])''')
box = box.replace('tool.add_vertex(center + basis * points[vertex_index])', 'tool.add_vertex(points[vertex_index])').replace('var normal: Vector3 = (basis * face[4]).normalized()', 'var normal: Vector3 = face[4]')
box += '''
	tool.index()
	var piece := MeshInstance3D.new()
	bake_box_count += 1
	piece.name = "Peca_%s_%04d" % [material_key, bake_box_count]
	piece.mesh = tool.commit()
	piece.position = center
	piece.rotation = rotation
	piece.set_meta("fase_conversao", bake_phase)
	piece.set_meta("pavimento", floor_id)
	piece.set_meta("material_original", material_key)
	piece.set_meta("_edit_group_", true)
	_raiz_visual.add_child(piece)
	if solid and _corpos_colisao.has(floor_id):
		bake_body(piece, Vector3.ZERO, size, Vector3.ZERO, "Colisao_Acompanha_Peca")
'''
# Helpers compostos viram raízes próprias; todas as partes e colisões seguem o gizmo.
wraps = {
'_adicionar_modelo_mobiliario': ('"Modelo_" + asset_id', 'origem', 'floor_id'),
'_adicionar_modelo_glb': ('"Modelo_" + asset_name', 'origem', 'floor_id'),
'_adicionar_cozinha_kitchen004_c16': ('"Cozinha_Richard_Preservada"', 'Vector3(-3.467222, y + 0.022, -6.9333043)', '&"terreo"'),
'_adicionar_tapete': ('"Tapete"', 'center', 'floor_id'),
'_adicionar_mesa': ('"Mesa"', 'origin', 'floor_id'),
'_adicionar_cadeira': ('"Cadeira"', 'origin', 'floor_id'),
'_adicionar_sofa': ('"Sofa"', 'origin', 'floor_id'),
'_adicionar_cama': ('"Cama"', 'origin', 'floor_id'),
'_adicionar_quadro_eixo_x': ('"Quadro"', 'center', 'floor_id'),
'_adicionar_quadro_eixo_z': ('"Quadro"', 'center', 'floor_id'),
'_adicionar_banquetas_cozinha': ('"Banqueta_Cozinha"', 'center', '&"terreo"'),
'_adicionar_faca_preparo_cozinha': ('"Faca_" + id', 'base', '&"terreo"'),
'_adicionar_pano_cozinha': ('"Pano_" + id', 'center', '&"terreo"'),
'_adicionar_arte_quadro_escritorio_c15': ('"Arte_Escritorio"', 'centro', '&"terreo"'),
'_adicionar_arte_quadro_biblioteca': ('"Arte_Biblioteca"', 'centro', '&"terreo"'),
'_adicionar_placa_sala': ('"Placa_" + texto', 'origem', '&""'),
'_adicionar_escada': ('"Escada_" + String(floor_id)', 'lower', 'floor_id'),
'_adicionar_escada_servico_porao': ('"Escada_Servico_Porao"', 'lower', '&"porao"'),
'_adicionar_acabamento_escada_c17': ('"GuardaCorpo_Servico"', 'Vector3(7.8,0.0,-5.6)', '&"terreo"'),
'_adicionar_planta_interior': ('"Planta"', 'origem', 'floor_id'),
}
wrappers = []
for name, (label,pivot,piso) in wraps.items():
    sig = re.search(r'^func '+name+r'\((.*)\) -> ([^:]+):', src, re.M)
    if not sig: raise RuntimeError(name)
    args = sig[1]
    # Split commas outside constructors in default parameters.
    parts = re.split(r',\s*(?![^()]*\))', args)
    callargs = ', '.join(p.split(':')[0].strip() for p in parts)
    rettype = sig[2]
    ret = 'var result = ' if rettype != 'void' else ''
    wrappers.append(f'''func {name}({args}) -> {rettype}:
	var previous := _raiz_visual
	var item := bake_enter({label}, {piso})
	{ret}super.{name}({callargs})
	bake_exit(previous, item, {pivot})
''' + ('\treturn result\n' if ret else ''))
output = head+'\n'+box+'\n'+'\n'.join(wrappers)
(ROOT/'qa/whole_house/bake_source.gd').write_text(output)
print('Adaptador gerado:', len(output), 'bytes')
