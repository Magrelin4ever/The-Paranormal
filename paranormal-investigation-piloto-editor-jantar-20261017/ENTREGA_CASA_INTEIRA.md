# Entrega — casa inteira

**Fonte oficial:** [Magrelin4ever/The-Paranormal](https://github.com/Magrelin4ever/The-Paranormal). Usar Godot **4.7.2 — Linux Compatibility**.

## O que foi entregue

A casa completa está em [`prototype/whole_house/casa_editavel.tscn`](prototype/whole_house/casa_editavel.tscn), com as cenas de cômodo em [`prototype/whole_house/rooms/`](prototype/whole_house/rooms/). São **4 pavimentos** (porão, térreo, primeiro andar e sótão/segundo andar), além do exterior. Móveis editáveis e suas colisões estão vinculados: selecione a raiz móvel, não uma subpeça. A **cozinha Richard** foi preservada.

Edite a casa completa ou um cômodo e salve com Ctrl+S. As mesmas cenas salvas são carregadas por F5, sem reconstrução procedural. Não execute scripts históricos de bake/build/refine/finalize/polish: eles podem sobrescrever as alterações atuais. Não acenda luzes novas nem adicione emissão.

O passo a passo está no [Guia de edição](GUIA_EDICAO_CASA_INTEIRA.md). O projeto abre diretamente por [`project.godot`](project.godot). Capturas usadas na validação ficam em [`qa/whole_house/previews/`](qa/whole_house/previews/).

## Verificações registradas

- **Física:** auditoria aprovada em **22 áreas**, com exceção explícita da **cozinha conservada** (não foi alterada pela auditoria). Sem falhas no JSON; razão de espaço livre conectado exigida: 0,95, obtida conforme cada área.
- **Escadas:** **6 rotas aprovadas** (térreo↔primeiro, primeiro↔sótão e porão↔térreo, nos dois sentidos), com o player real, gravidade original e cápsula 0,35/1,7; sem teleporte.
- **Persistência:** **58/58 checks aprovados**. O resultado registra 40 cenas nativas, 28 portas interativas, 0 luzes internas ativas, 0 materiais emissivos internos ativos, geometria 8644→8644 (não recriada) e, em cada pavimento, salvar/reabrir, mover, girar, adicionar asset, carregar no jogo e carregar a colisão movida.
- **Cenas editáveis:** 40 cenas carregadas, 8.716 malhas com owner salvo, 546 corpos e 574 formas de colisão; sem dependências ausentes ou falhas geométricas. Pequenos adereços decorativos têm isenções individuais justificadas no relatório; os três obstáculos grandes restantes da sala receberam colisão filha da raiz móvel.
- **Plugin:** 4 viewports testados quanto ao estado das máscaras; atribuição de novo asset, persistência, desfazer e cena original inalterada aprovados. O salvamento real pelo editor com filtro ativo retornou sucesso e **0 overrides `visible = false`**, conforme `editor_save_results.json`.
- **Iluminação:** contrato do shader aprovado; três feixes da lanterna preservados. A comparação de pixels é **somente da captura testada** (`lanterna_on.png`/`lanterna_off.png`, 960×540): 341.321 pixels ficaram claramente mais claros e 0 pixels desligados violaram a regra. Isso não afirma comparação de todo o cenário nem perfeição visual em 100% das situações.
- **Interiores:** PASS, sem falhas ou avisos; 8.644 meshes, 8.822 superfícies e **8.149 materiais-base únicos** verificados, com todas as emissões interiores desativadas. As três luzes da lanterna, fora da casa, foram excluídas dessa contagem.

Os JSON completos estão em [`qa/whole_house/`](qa/whole_house/): `physics_rooms_results.json`, `persistence_results.json`, `stair_navigation_results.json`, `lighting_results.json`, `pixel_lighting_results.json`, `interior_lighting_results.json`, `editor_plugin_results.json` e `protected_source_hashes.json`. Estes resultados documentam o estado testado; alterações futuras devem ser validadas novamente com F5.

## Créditos e proveniência

Consulte os manifests reais versionados: [`qa/whole_house/conversion_manifest.json`](qa/whole_house/conversion_manifest.json), [`qa/whole_house/recovery_manifest.json`](qa/whole_house/recovery_manifest.json), [`prototype/assets/models/bathroom_20261019/manifest.json`](prototype/assets/models/bathroom_20261019/manifest.json), [`prototype/assets/textures/polyhaven/c2_pbr_textures_2k_manifest.json`](prototype/assets/textures/polyhaven/c2_pbr_textures_2k_manifest.json) e [`prototype/assets/models/custom/c15/c15_original_manifest.json`](prototype/assets/models/custom/c15/c15_original_manifest.json). Eles apontam, entre outras fontes, para [Poly Haven](https://polyhaven.com/), [ambientCG](https://ambientcg.com/), [Innerscene](https://www.innerscene.com/) e suas licenças declaradas; a geometria C15 é original do projeto.

## Limite da prévia geral

A vista superior muito afastada da composição completa não foi validada de forma confiável no editor Compatibility com llvmpipe desta máquina. A causa não foi confirmada; não se afirma que seja um defeito do Godot ou do arquivo. O fluxo recomendado é a edição das cenas individuais dos cômodos, que alimentam a mesma casa no F5. Os testes de persistência, navegação e iluminação acima são independentes dessa captura geral. Essa ressalva não deve ser apresentada como uma vista geral totalmente aprovada.

Esta entrega não promete perfeição 100%: os limites acima são os do conjunto de testes e das capturas efetivamente executadas.
