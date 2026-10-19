from pathlib import Path
import re, json
R=Path(__file__).parents[2]/'prototype/whole_house/rooms'
checks={}
def ck(name,ok,detail): checks[name]={'ok':bool(ok),'detail':detail}
s=(R/'terreo__Escritorio.tscn').read_text(); ck('c15_roots', all(x in s for x in ['Mesa_C15_Editable','Cadeira_C15_Editable']), 'mesa/cadeira roots'); ck('c15_colliders', all(x in s for x in ['Hitbox_Mesa_Escritorio_C15','Hitbox_Cadeira_Escritorio_C15']), 'colliders retained')
h=(R/'terreo__Hall_Entrada.tscn').read_text(); ck('hall_roots', all(x in h for x in ['Console_C19_Editable','Banco_C19_Editable']), 'console/banco roots'); ck('hall_partition_metadata','global_centroid_x_lt_0' in h and 'global_centroid_x_ge_0' in h,'partition policy')
a=(R/'terreo__Area_Servico.tscn').read_text(); ck('service_roots', all(x+'_Edit' in a for x in ['BancadaServicoC18','RetornoServicoC18','AereosServicoC18','AspiradorServicoC18','BaldeServicoC18']),'five editable roots'); ck('service_colliders', 'BancadaServicoC18' in a and 'RetornoServicoC18' in a,'existing colliders retained')
k=(R/'terreo__Cozinha_Richard.tscn').read_text(); ck('kitchen_no_root_edit_group','Cozinha_Richard_Preservada_047' in k and 'metadata/_edit_group_ = true' not in k.split('[node name="Cozinha_Richard_Preservada_047"',1)[1].split('[node name=',1)[0],'root grouping removed'); ck('kitchen_components',k.count('metadata/editable_component = true')>=8,'imported meshes marked')
report={'checks':checks,'pass':all(v['ok'] for v in checks.values())}
Path(__file__).with_name('editable_parts_test_results.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
print(json.dumps(report,indent=2,ensure_ascii=False))
raise SystemExit(0 if report['pass'] else 1)
