"""Gera pontos de QA a partir da planta original, sem alterar móveis ou paredes."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
rooms = []
def room(name, floor, y, bounds, exits):
    rooms.append((name, floor, y, bounds, exits))

room('Lavanderia_Norte', 'porao', -2.85, (-9.3, -2.6, -8, -3), [(-6,-3),(-2.6,-5.35)])
room('Deposito_Centro', 'porao', -2.85, (-9.3,-2.6,-3,1.7), [(-6,-3),(-2.6,0)])
room('Frente_Oeste', 'porao', -2.85, (-9.3,-2.6,1.7,8), [(-2.6,5.25)])
room('Oficina', 'porao', -2.85, (-2.6,5.25,-8,1.7), [(-2.6,-5.35),(-2.6,0),(5.25,-6.25),(0,1.7),(5.25,-.4)])
room('Baia_Escada', 'porao', -2.85, (5.25,9.3,-8,-2.8), [(5.25,-6.25)])
room('Apoio_Escada', 'porao', -2.85, (5.25,9.3,-2.8,1.7), [(5.25,-.4)])
room('Frente_Leste', 'porao', -2.85, (-2.6,9.3,1.7,8), [(0,1.7),(-2.6,5.25)])

for side, left, right in [('Oeste',-9.3,-1.85),('Leste',1.85,9.3)]:
    hall = -1.85 if side == 'Oeste' else 1.85
    center = -5.55 if side == 'Oeste' else 5.55
    names = ['Cozinha_Richard','Sala_Jantar','Sala_Estar'] if side == 'Oeste' else ['Area_Servico','Biblioteca','Escritorio']
    room(names[0], 'terreo', 0, (left,right,-8,-2.8), [(hall,-5.35),(center,-2.8)])
    room(names[1], 'terreo', 0, (left,right,-2.8,2.5), [(hall,-.2),(center,-2.8),(center,2.5)])
    room(names[2], 'terreo', 0, (left,right,2.5,8), [(hall,5.15),(center,2.5)])
room('Hall_Entrada', 'terreo', 0, (-1.85,1.85,-8,8), [(0,7.5),(0,3.5),(-1.85,-5.35),(1.85,-5.35),(-1.85,-.2),(1.85,-.2),(-1.85,5.15),(1.85,5.15)])

for side,left,right in [('Oeste',-7.6,-1.8),('Leste',1.8,7.6)]:
    hall = -1.8 if side == 'Oeste' else 1.8
    center = -4.4 if side == 'Oeste' else 4.4
    names = ['Quarto_Infantil','Closet_Infantil','Banheiro_Familiar'] if side == 'Oeste' else ['Suite_Casal','Closet_Casal','Banheiro_Suite']
    room(names[0], 'primeiro', 2.85, (left,right,-6.2,-.8), [(hall,-3.25),(center,-.8)])
    room(names[1], 'primeiro', 2.85, (left,right,-.8,2), [(hall,.55),(center,-.8),(center,2)])
    room(names[2], 'primeiro', 2.85, (left,right,2,6.2), [(hall,4),(center,2)])
room('Hall_Superior', 'primeiro', 2.85, (-1.8,1.8,-6.2,6.2), [(0,-1.45),(0,5.1),(-1.8,-3.25),(1.8,-3.25),(-1.8,.55),(1.8,.55),(-1.8,4),(1.8,4)])
# O sótão é um único ambiente contínuo com vazio de escada no centro sul.
room('Sotao_Arquivo_E_Deposito', 'sotao', 5.7, (-7.6,7.6,-6.2,6.2), [(0,.85),(-2,3),(2,3)])

lines = ['[gd_scene format=3]', '', '; Apenas QA. Não é instanciado no jogo.', '[node name="MarcadoresRotas" type="Node3D"]', '']
for name,floor,y,(x0,x1,z0,z1),exits in rooms:
    label = floor+'_'+name
    lines += [f'[node name="{label}" type="Node3D" parent="." groups=["whole_house_room"]]', f'metadata/room_id = "{label}"', f'metadata/pavimento = "{floor}"', f'metadata/audit_bounds_min = Vector3({x0+.15}, {y}, {z0+.15})', f'metadata/audit_bounds_max = Vector3({x1-.15}, {y}, {z1-.15})', f'metadata/audit_y = {y}', '']
    for idx,(x,z) in enumerate(exits):
        lines += [f'[node name="Saida_{idx+1}" type="Marker3D" parent="{label}" groups=["whole_house_exit"]]', f'position = Vector3({x}, {y}, {z})', f'metadata/audit_room_id = "{label}"', '']
path = ROOT/'prototype/whole_house/marcadores_rotas.tscn'
path.write_text('\n'.join(lines)+'\n')
print(f'Marcadores: {len(rooms)} regiões reais em {path}')
