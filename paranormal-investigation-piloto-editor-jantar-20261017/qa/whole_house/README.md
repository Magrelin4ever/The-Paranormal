# Validação da casa inteira e do gameplay

Os testes registrados foram executados com Godot **4.7.2**, Linux e renderer Compatibility/OpenGL. As instruções de jogo estão em [`../../JOGAR_E_CONTROLES.md`](../../JOGAR_E_CONTROLES.md); a edição persistente está descrita em [`../../GUIA_EDICAO_CASA_INTEIRA.md`](../../GUIA_EDICAO_CASA_INTEIRA.md).

## Bateria repetível

Execute da pasta que contém `project.godot`:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script res://qa/whole_house/audit_static.gd
godot --headless --path . --script res://qa/whole_house/audit_all_editable_scenes.gd
godot --headless --path . --script res://qa/whole_house/audit_physics_rooms.gd
godot --headless --path . --script res://qa/whole_house/persistence_test.gd
godot --headless --path . --script res://qa/whole_house/validate_interior_lighting.gd
godot --headless --path . --script res://qa/whole_house/lighting_darkness_test.gd
godot --headless --fixed-fps 60 --path . --script res://qa/whole_house/stair_navigation_test.gd
godot --headless --path . --script res://qa/whole_house/exit_marker_walk_test.gd
godot --headless --path . --script res://qa/whole_house/door_e_interaction_test.gd
godot --headless --path . --script res://qa/gameplay/evidence_line_of_sight_test.gd
godot --headless --path . --script res://qa/gameplay/gameplay_flow_test.gd
```

`exit_marker_walk_test.gd` usa o `CharacterBody3D`, `move_and_slide`, gravidade e a cápsula real para percorrer **61/61 marcadores**. O percurso é contínuo entre as saídas de cada cômodo; há **um posicionamento inicial em cada um dos 22 cômodos**, portanto o relatório não afirma uma caminhada única e ininterrupta pela casa inteira. `stair_navigation_test.gd` verifica separadamente seis rotas reais de escada, sem teleporte durante cada rota. `door_e_interaction_test.gd` envia a tecla **E** ao jogador real e abre/fecha as 28 portas.

A auditoria física mede espaço livre com cápsula de 0,35 m em grade de 0,18 m, conectividade e acessibilidade de saídas; não substitui um teste prolongado de jogo humano. O teste de persistência de camadas de assets requer o editor e salva apenas em `user://`.

## Prévia do editor

Para testar o enquadramento, use o editor gráfico com Compatibility/OpenGL:

```bash
HOUSE_EDITOR_OVERVIEW_QA=1 godot --editor --path . --scene res://prototype/whole_house/casa_editavel.tscn
```

A câmera adapta a distância à proporção do viewport. A captura `previews/editor_overview_verified.png` mostra agora a casa e o exterior completos em perspectiva; não é um corte que revele o interior de todos os pisos. O editor restaura as propriedades originais antes de salvar. Os resultados em llvmpipe não medem desempenho nem substituem validação em GPU integrada física.

## Assets e proveniência

A cozinha Kitchen004C16 e seus meshes/materiais derivados sem licença comprovável foram removidos da branch. A cozinha atual é uma cena autoral modular. `kitchen_baseline_snapshot.json` conserva apenas bounds, nomes e transforms, sem geometria; `DISTRIBUTION_BLOCKED.md` registra o motivo da remoção. O forno Tripo permanece fora da cena ativa e sem liberação de direitos.

Os scripts históricos com nomes `bake`, `build`, `create_bake`, `finalize`, `refine`, `split`, `polish` e `finish` podem sobrescrever a casa. Não os execute para abrir ou jogar; o runtime carrega as cenas `.tscn` salvas.
