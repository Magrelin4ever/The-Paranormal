# Validação da casa inteira

Os resultados JSON e as capturas em `previews/` registram o estado efetivamente testado no Godot 4.7.2, Linux, Compatibility/OpenGL. O guia de uso está em `../../GUIA_EDICAO_CASA_INTEIRA.md`.

## Testes para repetir

Execute a partir da pasta que contém `project.godot`, usando o seu executável Godot 4.7.2 no lugar de `godot`:

```bash
godot --headless --path . --script qa/whole_house/audit_all_editable_scenes.gd
godot --headless --path . --script qa/whole_house/audit_physics_rooms.gd
godot --headless --path . --script qa/whole_house/persistence_test.gd
godot --headless --path . --script qa/whole_house/validate_interior_lighting.gd
godot --headless --path . --script qa/whole_house/lighting_darkness_test.gd
godot --headless --fixed-fps 60 --path . --script qa/whole_house/stair_navigation_test.gd
```

A persistência grava cópias temporárias em `user://`; não altera os cômodos de produção. O teste físico abre as portas em uma instância isolada do jogo. Ambos geram seus resultados nesta pasta. Pequenos adereços sem colisão são identificados individualmente no relatório de editabilidade, com justificativa; móveis e obstáculos grandes exigem colisão filha da raiz móvel.

Para gerar capturas reais, execute `render_suite.gd` com renderização Compatibility disponível e compare `lanterna_on.png` e `lanterna_off.png` com `compare_flashlight_pixels.py`. A comparação desativa o grão apenas na captura para eliminar ruído temporal. O teste do plugin é opt-in: abrir a casa no editor com `HOUSE_EDITOR_QA=1` gera `editor_plugin_results.json`, sem salvar alterações na cena original.

## Ferramentas históricas: não executar para editar

Os scripts com nomes `bake`, `build`, `create_bake`, `finalize`, `refine`, `split`, `polish` e `finish` documentam a conversão e a montagem desta entrega. **Eles podem sobrescrever a disposição atual dos cômodos.** Não são necessários para abrir o projeto, editar móveis, acrescentar assets ou rodar o jogo. O jogo carrega diretamente as cenas `.tscn` salvas, sem chamar esses construtores.
