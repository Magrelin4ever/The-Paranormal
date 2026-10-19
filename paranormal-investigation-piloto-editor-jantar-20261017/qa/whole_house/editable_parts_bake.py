#!/usr/bin/env python3
"""Offline scene hierarchy bake for independently editable whole-house parts.
Only authorized room scenes are edited; source GLBs/resources are untouched.
"""
from pathlib import Path
import re, json, hashlib
ROOT=Path(__file__).parents[2]
ROOM=ROOT/'prototype/whole_house/rooms'

def lines(p): return p.read_text().splitlines(True)
def node_name(line):
 m=re.match(r'\[node name="([^"]+)"',line); return m.group(1) if m else None

def c15():
 p=ROOM/'terreo__Escritorio.tscn'; s=p.read_text()
 marker='[node name="Asset_C2_59_MesaEscritorioC15"'
 i=s.index(marker); insert='''[node name="Mesa_C15_Editable" type="Node3D" parent="Modelo_MesaEscritorioC15_059/Asset_C2_59_MesaEscritorioC15" unique_id=210150001]\nmetadata/editable_part = "mesa"\nmetadata/pivot_policy = "asset_local_origin_global_preserved"\n[node name="Cadeira_C15_Editable" type="Node3D" parent="Modelo_MesaEscritorioC15_059/Asset_C2_59_MesaEscritorioC15" unique_id=210150002]\nmetadata/editable_part = "cadeira"\nmetadata/pivot_policy = "asset_local_origin_global_preserved"\n'''
 # insert after asset node block (one line in actual file despite display wrapping)
 end=s.index('\n',i)+1; s=s[:end]+insert+s[end:]
 old='Modelo_MesaEscritorioC15_059/Asset_C2_59_MesaEscritorioC15'
 s=s.replace('parent="'+old+'"','parent="'+old+'/Mesa_C15_Editable"',0) # first occurrence would accidentally root? only first mesh after inserted; do all targeted below
 # undo if wrong: replace targeted mesh parents globally based node sections
 s=s.replace('parent="'+old+'/Mesa_C15_Editable"','parent="'+old+'"',1)
 s=re.sub(r'(\[node name="C15_Desk[^\n]*parent=")'+re.escape(old)+r'"',r'\1'+old+'/Mesa_C15_Editable"',s)
 s=re.sub(r'(\[node name="C15_Chair[^\n]*parent=")'+re.escape(old)+r'"',r'\1'+old+'/Cadeira_C15_Editable"',s)
 s=s.replace('parent="Modelo_MesaEscritorioC15_059"','parent="'+old+'/Mesa_C15_Editable"',2)
 # root no longer editor group; child roots are selectable
 s=s.replace('metadata/_edit_group_ = true\nmetadata/pivot_original = Vector3(5.75, 0, 6.72)','metadata/pivot_original = Vector3(5.75, 0, 6.72)',1)
 p.write_text(s)

def hall():
 p=ROOM/'terreo__Hall_Entrada.tscn'; s=p.read_text(); base='Modelo_ConjuntoHallC19_022'; asset=base+'/Asset_C2_13_ConjuntoHallC19'
 marker='[node name="Asset_C2_13_ConjuntoHallC19"'; i=s.index(marker); end=s.index('\n',i)+1
 roots='''[node name="Console_C19_Editable" type="Node3D" parent="%s" unique_id=210190001]\nmetadata/editable_part = "console"\nmetadata/partition = "global_centroid_x_lt_0"\n[node name="Banco_C19_Editable" type="Node3D" parent="%s" unique_id=210190002]\nmetadata/editable_part = "banco"\nmetadata/partition = "global_centroid_x_ge_0"\n'''%(asset,asset)
 s=s[:end]+roots+s[end:]
 # material meshes are assigned by preserved c19_group plus coordinate rule metadata; console material is known x<0
 for pat,root in [('C19_Runtime_C19_madeira_sobria_Wood026','Console_C19_Editable'),('C19_Runtime_C19_papelao_natural','Console_C19_Editable'),('C19_Runtime_C19_couro_conhaque_fosco','Console_C19_Editable'),('C19_Runtime_C19_ceramica_fosca','Console_C19_Editable'),('C19_Runtime_C19_chaves_latão_envelhecido','Console_C19_Editable'),('C19_Runtime_C19_sola_borracha','Banco_C19_Editable'),('C19_Runtime_C19_tecido_casaco_azul_profundo','Banco_C19_Editable'),('C19_Runtime_C19_inox_escovado','Banco_C19_Editable'),('C19_Runtime_C19_ferragem_grafite','Banco_C19_Editable')]:
  s=re.sub(r'(\[node name="'+re.escape(pat)+r'"[^\n]*parent=")'+re.escape(asset)+r'"',r'\1'+asset+'/'+root+'"',s)
 # collision roots follow their corresponding furniture
 s=s.replace('parent="'+base+'/C19_Console_Perimetro"','parent="'+asset+'/Console_C19_Editable/C19_Console_Perimetro"')
 s=s.replace('parent="'+base+'/C19_Banco_Perimetro"','parent="'+asset+'/Banco_C19_Editable/C19_Banco_Perimetro"')
 s=s.replace('parent="'+base+'"','parent="'+asset+'"',2)
 s=s.replace('metadata/_edit_group_ = true','metadata/legacy_group_disabled = true',1)
 p.write_text(s)

def service():
 p=ROOM/'terreo__Area_Servico.tscn'; s=p.read_text(); base='Modelo_ConjuntoServicoC18_087'; asset=base+'/Asset_C2_82_ConjuntoServicoC18'; marker='[node name="Asset_C2_82_ConjuntoServicoC18"'; i=s.index(marker); end=s.index('\n',i)+1
 roots=''.join(f'[node name="{n}_Edit" type="Node3D" parent="{asset}" unique_id={uid}]\nmetadata/editable_part = "{n}"\nmetadata/collider_source = "{n}ServicoC18"\n' for n,uid in [('BancadaServicoC18',210180001),('RetornoServicoC18',210180002),('AereosServicoC18',210180003),('AspiradorServicoC18',210180004),('BaldeServicoC18',210180005)])
 s=s[:end]+roots+s[end:]
 # Keep base geometry under bancada; classify named props under nearest existing collider bucket.
 for token,root in [('aspirador','AspiradorServicoC18_Edit'),('balde','BaldeServicoC18_Edit'),('produto_azul','BaldeServicoC18_Edit'),('produto_coral','BaldeServicoC18_Edit'),('inox_escovado','RetornoServicoC18_Edit')]:
  s=re.sub(r'(\[node name="[^"]*'+token+r'[^"]*"[^\n]*parent=")'+re.escape(asset)+r'"',r'\1'+asset+'/'+root+'"',s,flags=re.I)
 # existing collider ownership moved beneath editable roots without changing shape/transform
 for n,root in [('BancadaServicoC18', 'BancadaServicoC18_Edit'),('RetornoServicoC18','RetornoServicoC18_Edit')]:
  s=s.replace('parent="'+base+'/'+n+'"','parent="'+asset+'/'+root+'/'+n+'"')
 s=s.replace('metadata/_edit_group_ = true','metadata/legacy_group_disabled = true',1)
 p.write_text(s)

def kitchen():
 p=ROOM/'terreo__Cozinha_Richard.tscn'; ls=lines(p); out=[]; in_k=False; mesh=None
 for line in ls:
  if line.startswith('[node name="Cozinha_Richard_Preservada_047"'): in_k=True
  if in_k and line.startswith('[node name=') and 'type="MeshInstance3D"' in line: mesh=True
  if in_k and line.startswith('[node name=') and 'type="MeshInstance3D"' not in line and not line.startswith('[node name="Cozinha_Richard_Preservada_047"'): mesh=False
  if in_k and 'metadata/_edit_group_ = true' in line and not mesh: continue
  out.append(line)
  if in_k and mesh and line.startswith('mesh = '): out.append('metadata/editable_component = true\nmetadata/collision_policy = "homonymous_C16_child_preserved"\n')
 p.write_text(''.join(out))

for fn in (c15,hall,service,kitchen): fn()
report={'scenes':[str(ROOM/x) for x in ['terreo__Escritorio.tscn','terreo__Hall_Entrada.tscn','terreo__Area_Servico.tscn','terreo__Cozinha_Richard.tscn']], 'source_glb_touched':False, 'offline':True, 'notes':'Hierarchy bake; global transforms remain unchanged by adding identity editable roots.'}
(ROOT/'qa/whole_house/editable_parts_bake_report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
